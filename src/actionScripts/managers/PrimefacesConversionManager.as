package actionScripts.managers
{
	import flash.events.Event;
	import flash.events.EventDispatcher;
	import flash.filesystem.File;
	
	import actionScripts.events.PrimefacesConversionEvent;
	import actionScripts.utils.Logger;
	import actionScripts.valueObjects.FileWrapper;
	import actionScripts.valueObjects.PrimefacesCommand;
	
	[Event(name="CONVERSIONS_COMPLETED", type="flash.events.Event")]
	[Event(name="CONVERSIONS_FAILED", type="flash.events.Event")]
	public class PrimefacesConversionManager extends EventDispatcher
	{
		public static const CONVERSIONS_COMPLETED:String = "conversionsCompleted";
		public static const CONVERSIONS_FAILED:String = "conversionsFailed";
		
		public var primefacesCommand:PrimefacesCommand;
		
		private var invokedFromDirectory:File;
		private var isOverwrite:Boolean;
		private var pendingQueue:Vector.<File> = new Vector.<File>();
		private var logger:Logger = Logger.getInstance();
		
		public function PrimefacesConversionManager(invokedFromDirectory:File, isOverwrite:Boolean)
		{
			this.invokedFromDirectory = invokedFromDirectory;
			this.isOverwrite = isOverwrite;
		}
		
		public function start():void
		{
			// in case of directory source having
			// having folder or sub-folders
			if (primefacesCommand.sourcePrimefaces.isDirectory)
			{
				initFolderConversion();
			}
			// non-directory source
			else
			{
				pendingQueue.push(primefacesCommand.sourcePrimefaces);
				flush();
			}
		}
		
		private function flush():void
		{
			if (pendingQueue.length != 0)
			{
				startSingleFileConversion(pendingQueue[0], onSuccessOrError);
				pendingQueue.shift();
			}
			else
			{
				this.dispatchEvent(new Event(CONVERSIONS_COMPLETED));
			}
			
			/*
			* @local
			*/
			function onSuccessOrError(message:String, isSuccess:Boolean):void
			{
				if (pendingQueue.length == 0 && !isSuccess)
				{
					// just terminate the process as we have
					// nothing to do after this
					throw new Error(message);
					return;
				}
				
				logger.update(message, isSuccess ? Logger.TYPE_INFO : Logger.TYPE_ERROR);
				flush();
			}
		}
		
		private function startSingleFileConversion(source:File, onSuccessOrError:Function):void
		{
			var calculatedTarget:File = primefacesCommand.targetPrimefaces;
			
			// further calculation over target
			if (!calculatedTarget || calculatedTarget.isDirectory)
			{
				var nameSplit:Array = source.name.split(".");
				nameSplit.pop();
				var targetXHTMLName:String = nameSplit.join(".") +".xhtml";
				calculatedTarget = !calculatedTarget ?
					source.parent.resolvePath(targetXHTMLName) :
					getMirroredPath(primefacesCommand.sourcePrimefaces, source, calculatedTarget, targetXHTMLName);
			}
			
			var tmpConversion:PrimefacesConverter = new PrimefacesConverter(source, calculatedTarget, isOverwrite);
			manageListeners(tmpConversion, true);
			
			/*
			 * @local
			 */
			function onConverterSuccess(event:PrimefacesConversionEvent):void
			{
				manageListeners(event.target as PrimefacesConverter, false);
				onSuccessOrError(event.message, true);
			}
			function onConverterError(event:PrimefacesConversionEvent):void
			{
				manageListeners(event.target as PrimefacesConverter, false);
				onSuccessOrError(event.message, false);
			}
			function manageListeners(origin:PrimefacesConverter, attach:Boolean):void
			{
				if (attach)
				{
					origin.addEventListener(PrimefacesConversionEvent.CONVERSION_SUCCESS, onConverterSuccess);
					origin.addEventListener(PrimefacesConversionEvent.CONVERSION_ERROR, onConverterError);
				}
				else
				{
					origin.removeEventListener(PrimefacesConversionEvent.CONVERSION_SUCCESS, onConverterSuccess);
					origin.removeEventListener(PrimefacesConversionEvent.CONVERSION_ERROR, onConverterError);
				}
			}
		}
		
		private function initFolderConversion():void
		{
			// generate target directory if given and does not exists
			if (primefacesCommand.targetPrimefaces && 
				(!primefacesCommand.targetPrimefaces.exists || !primefacesCommand.targetPrimefaces.isDirectory))
			{
				try
				{
					primefacesCommand.targetPrimefaces.createDirectory();
				}
				catch (e:Error)
				{
					throw new Error("Unable to create target directory: "+ primefacesCommand.targetPrimefaces.nativePath +"\n"+ e.getStackTrace());
					return;
				}
			}
			
			var tmpWrapper:FileWrapper = new FileWrapper(primefacesCommand.sourcePrimefaces, true);
			parseChildrens(tmpWrapper);
		}
		
		private function parseChildrens(value:Object):void
		{
			if (!value) return;
			
			var extension: String = value.file.extension;
			if ((value.children is Array) && (value.children as Array).length > 0) 
			{
				var tmpTotalChildrenCount:int = value.children.length;
				for (var c:int=0; c < value.children.length; c++)
				{
					extension = value.children[c].file.extension;
					var isAcceptable:Boolean = (extension != null) ? (extension.toLowerCase() == "xml") : false;
					if (!value.children[c].file.isDirectory && isAcceptable)
					{
						pendingQueue.push(value.children[c].file);
					}
					else if (!value.children[c].file.isDirectory && !isAcceptable)
					{
						value.children.splice(c, 1);
						tmpTotalChildrenCount --;
						c--;
					}
					else if (value.children[c].file.isDirectory) 
					{
						//lastChildren = value.children;
						parseChildrens(value.children[c]);
						if (!value.children[c].children || (value.children[c].children && value.children[c].children.length == 0)) 
						{
							value.children.splice(c, 1);
							c--;
						}
					}
				}
				
				// when recursive listing done
				if (value.isRoot)
				{
					this.flush();
				}
			}
			else 
			{
				this.flush();
			}
		}
		
		private function getMirroredPath(by:File, forPath:File, to:File, name:String):File
		{
			var subPath:String = forPath.parent.nativePath.replace(by.nativePath, "");
			// this requires to be in a separate check
			if (subPath.charAt(0) == File.separator) subPath = subPath.replace(File.separator, "");
			subPath += (subPath == "") ? name : File.separator + name;
			return (to.resolvePath(subPath));
		}
	}
}