package  
{
	import flash.display.MovieClip;
	import flash.text.TextField;
	/**
	 * Просто кнопка
	 * @author Alexander Semikolenov (alex.semikolenov@gmail.com)
	 */
	public class Bt extends MovieClip
	{
		public var txtText	:TextField;
		
		public function Bt() 
		{
			mouseChildren	= false
			buttonMode		= true
		}
		// STATIC METHODS
		
		// ACCESSORS
		
		// PUBLIC METHODS
		/**
		 * Текст кнопки
		 */
		public function set text(txt:String):void
		{
			txtText.text = txt
		}
		public function get text():String
		{
			return txtText.text
		}
		
		// PROTECTED METHODS
		
		// EVENT HANDLERS
		
		// PRIVATE METHODS
	}

}