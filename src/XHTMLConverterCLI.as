package
{
    import flash.desktop.NativeApplication;
    import flash.display.Sprite;
    import flash.events.ErrorEvent;
    import flash.events.Event;
    import flash.events.InvokeEvent;
    import flash.events.UncaughtErrorEvent;
    import flash.filesystem.File;
    
    import actionScripts.managers.PrimefacesConversionManager;
    import actionScripts.utils.FileUtils;
    import actionScripts.utils.Logger;
    import actionScripts.valueObjects.PrimefacesCommand;
    
    [SWF(frameRate=60, width=0, height=0, visible=false, showStatusBar=false)]
    public class XHTMLConverterCLI extends Sprite
	{
		private var ifPublishToPrimefacesArg:PrimefacesCommand;
		private var invokedFromDirectory:File;
		private var isOverwrite:Boolean;
		
		private var logger:Logger = Logger.getInstance();
		private var pfConversionManager:PrimefacesConversionManager;
		
		public function XHTMLConverterCLI()
		{
			super();
			NativeApplication.nativeApplication.addEventListener(InvokeEvent.INVOKE, onInvokeEvent);
			loaderInfo.uncaughtErrorEvents.addEventListener(UncaughtErrorEvent.UNCAUGHT_ERROR, uncaughtErrorHandler);
		}
		
		private function onInvokeEvent(event:InvokeEvent):void
		{
			NativeApplication.nativeApplication.removeEventListener(InvokeEvent.INVOKE, onInvokeEvent);
			logger.checkPrevious(onPreviousChecked);
			
			/*
			 * @local
			 */
			function onPreviousChecked():void
			{
				invokedFromDirectory = event.currentDirectory;
				parseArguments(event.arguments);
			}
		}
		
		private function parseArguments(args:Array):void
		{
			logger.generateTimeStamp();
			logger.update("Started from: "+ invokedFromDirectory.nativePath);
			logger.update("Arguments ("+ args.length +"):\n\n"+ args.join("\n") +"\n");
			
			var source:File;
			var isDirectoryBased:Boolean;
			
			if (args.length != 0)
			{
				for (var i:int = 0; i < args.length; i++)
				{
					// parsing if publish-to-primefaces exists
					if (!ifPublishToPrimefacesArg && (args[i] == "--publish-to-primefaces"))
					{
						// next parameter can be a file or directory path
						if ((i + 1) < args.length)
						{
							source = FileUtils.convertIfRelativeToAbsolute(args[i+1], invokedFromDirectory);
							if (source) 
							{
								ifPublishToPrimefacesArg = new PrimefacesCommand();
								ifPublishToPrimefacesArg.sourcePrimefaces = source; 
							}
							
							// try to validate if an optional target
							// path also provided
							if (source && ((i + 2) < args.length) && (args[i+2].indexOf("--") == -1))
							{
								ifPublishToPrimefacesArg.targetPrimefaces = FileUtils.convertIfRelativeToAbsolute(args[i+2], invokedFromDirectory);
							}
							// if file based but no target has provided
							if (source && !source.isDirectory && !ifPublishToPrimefacesArg.targetPrimefaces)
							{
								ifPublishToPrimefacesArg = null;
							}
						}
					}
					
					// parse if requires overwrite
					if (args[i] == "--overwrite") isOverwrite = true;
				}
			}
			else
			{
				// if no argument present, saveLogAndQuit
				throw new Error("No Arguments Found");
			}
			
			processAfterArguments();
		}
		
		private function processAfterArguments():void
		{
			// --publish-to-primefaces
			if (ifPublishToPrimefacesArg)
			{
				pfConversionManager = new PrimefacesConversionManager(invokedFromDirectory, isOverwrite);
				pfConversionManager.primefacesCommand = ifPublishToPrimefacesArg;
				pfConversionManager.addEventListener(PrimefacesConversionManager.CONVERSIONS_COMPLETED, onPFConversionProcessReachEnd);
				pfConversionManager.addEventListener(PrimefacesConversionManager.CONVERSIONS_FAILED, onPFConversionProcessReachEnd);
				pfConversionManager.start();
			}
			else
			{
				throw new Error("Missing parameters. Expected path details not found: --publish-to-primefaces\n");
			}
		}
		
		private function onPFConversionProcessReachEnd(event:Event):void
		{
			pfConversionManager.removeEventListener(PrimefacesConversionManager.CONVERSIONS_COMPLETED, onPFConversionProcessReachEnd);
			pfConversionManager.removeEventListener(PrimefacesConversionManager.CONVERSIONS_FAILED, onPFConversionProcessReachEnd);
			
			// Unfortunately, even the invoke event do fire 
			// multiple times when an application is already open,
			// its argument array do not re-generates except in
			// the first time; thus, let close it and re-open the
			// app again
			exitWithReason("Saving file(s) completed at: "+ 
				(pfConversionManager.primefacesCommand.targetPrimefaces ? pfConversionManager.primefacesCommand.targetPrimefaces.nativePath : pfConversionManager.primefacesCommand.sourcePrimefaces.nativePath),
				Logger.TYPE_INFO);
		}
		
		private function saveLogAndQuit():void
		{
			logger.addEventListener(Logger.LOG_QUEUE_COMPLETED, onLogQueueCompleted);
			logger.update("Application has been closed.\n======================================\n\n");
			
			/*
			* @local
			*/
			function onLogQueueCompleted(event:Event):void
			{
				event.target.removeEventListener(Logger.LOG_QUEUE_COMPLETED, onLogQueueCompleted);
				stage.nativeWindow.close();
			}
		}
		
		private function uncaughtErrorHandler(event:UncaughtErrorEvent):void
		{
			var errorString:String;
			if (event.error is Error)
			{
				errorString = (event.error as Error).message;
			}
			else if (event.error is ErrorEvent)
			{
				errorString = (event.error as ErrorEvent).text +"\n"+ (event.error as Error).getStackTrace();
			}
			else
			{
				// a non-Error, non-ErrorEvent type was thrown and uncaught
				errorString = event.toString();
			}
			
			// finally
			exitWithReason(errorString, Logger.TYPE_ERROR);
		}
		
		private function exitWithReason(reason:String, type:String):void
		{
			logger.update(reason, type);
			saveLogAndQuit();
		}
    }
}