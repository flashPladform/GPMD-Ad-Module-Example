package ru.ngl.utils 
{
	/**
	 * ...
	 * @author Alexander Semikolenov
	 */
	public class Conversion 
	{
		
		public function Conversion()
		{
			throw new Error("You can't have an instance of Conversion")
		}
		
		// STATIC METHODS
 		/**
 		 * Преобразование целого числа (секунд), в временной формат формат HH:MM:SS
 		 * @param	num количество секунд
 		 * @param	count количество разрядов
 		 * @return время в формате HH:MM:SS
 		 */
		static public function secondToHMS(num:uint, count:uint=0):String
		{
			count = (count == 0)? 3 : count;
			count = (count > 4) ? 4 : count;
			
			var timeArr		:Array	= [1, 60, 3600, 86400];
			
			var arrNum		:Array	= new Array();
			for (var i:int = count-1; i >= 0; i--) 
			{
				arrNum.push(uint(num / timeArr[i]));
				num 			= num % timeArr[i];
			}
			
			var str 	:String	= String(arrNum[0]);
			for (i = 1; i < arrNum.length; i++) 
			{
				var val	:int	= arrNum[i] ;
				str				+= ":" + ((val < 10) ? "0" + val : val);
			}
			return str;
			
		}
		
		/**
		 * 
		 * Перевести время из формата [DD:]HH:MM:SS в секунды
		 * @param	d строка формаьа [DD:]HH:MM:SS
		 * @return количество секунд
		 */
		static public function hms2int(d:String):int
		{
			var timeArr		:Array	= [1, 60, 3600, 86400];
			var arDuration	:Array	= d.split(":");
			var second		:uint	= 0;
			
			arDuration				= arDuration.reverse();
			for (var i:int = 0; i < arDuration.length; i++) 
			{
				second += int(arDuration[i]) * timeArr[i];
			}
			return second;
		}
	}

}