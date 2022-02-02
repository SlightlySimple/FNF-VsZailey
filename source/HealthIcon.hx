package;

import flixel.FlxG;
import flixel.FlxSprite;
import openfl.utils.Assets as OpenFlAssets;

using StringTools;

class HealthIcon extends FlxSprite
{
	public var char:String = 'bf';
	public var isPlayer:Bool = false;
	public var isOldIcon:Bool = false;

	/**
	 * Used for FreeplayState! If you use it elsewhere, prob gonna annoying
	 */
	public var sprTracker:FlxSprite;

	public function new(?char:String = "bf", ?frames:Array<Int>, ?isPlayer:Bool = false)
	{
		super();

		this.char = char;
		this.isPlayer = isPlayer;

		isPlayer = isOldIcon = false;

		if (frames == null)
			frames = [0, 1];
		changeIcon(char, frames);
		scrollFactor.set();
	}

	public function changeIcon(char:String, ?frames:Array<Int>)
	{
		if (frames == null)
			frames = [0, 1];

		if (!OpenFlAssets.exists(Paths.image('icons/icon-' + char)))
			char = 'bf';

		var iconFolder:String = 'icons';
		if (FlxG.save.data.colorIcons && OpenFlAssets.exists(Paths.image('icons-color/icon-' + char)))
			iconFolder = 'icons-color';
		loadGraphic(Paths.loadImage(iconFolder + '/icon-' + char), true, 150, 150);
		antialiasing = FlxG.save.data.antialiasing;
		animation.add(char, frames, 0, false, isPlayer);
		animation.play(char);
	}

	override function update(elapsed:Float)
	{
		super.update(elapsed);

		if (sprTracker != null)
			setPosition(sprTracker.x + sprTracker.width + 10, sprTracker.y - 30);
	}
}
