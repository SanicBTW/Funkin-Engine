package base;

import base.system.DatabaseManager;

class SaveData
{
	public static var antialiasing:Bool = true;
	public static var showTrails:Bool = true;
	public static var downScroll:Bool = false;
	public static var middleScroll:Bool = false;

	public static function getSettings():Array<String>
	{
		var returnArray:Array<String> = [];
		for (field in Type.getClassFields(SaveData))
		{
			if (Type.typeof(Reflect.field(SaveData, field)) != TFunction)
				returnArray.push(field);
		}
		return returnArray;
	}

	public static function saveSettings()
	{
		for (field in getSettings())
		{
			DatabaseManager.set(field, Reflect.field(SaveData, field));
		}
		DatabaseManager.save();
	}

	public static function loadSettings()
	{
		for (field in getSettings())
		{
			var defaultValue:Dynamic = Reflect.field(SaveData, field);
			var save:Dynamic = DatabaseManager.get(field);
			Reflect.setField(SaveData, field, (save == null ? defaultValue : save));
		}
	}
}
