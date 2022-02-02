package;

import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;
import flixel.util.FlxColor;
import flixel.util.FlxSpriteUtil;
import openfl.Lib;

class ResultsScreenHealth extends FlxSpriteGroup
{
	var _width:Float;
	var _height:Float;

	public function new(x:Float, y:Float, width:Float, height:Float)
	{
		super(x, y);

		_width = width;
		_height = height;

		var bg = new FlxSprite(0, 0).makeGraphic(Std.int(_width), Std.int(_height), 0x99000000);
		bg.alpha = 0.6;
		add(bg);
	}

	public function generateGraph( data:Array<Array<Float>> )
	{
		var maxWValue:Float = data[data.length - 1][0];

		for (i in 0...data.length - 1)
		{
			var d = data[i];
			var e = data[i+1];

			var xx = Std.int((d[0] / maxWValue) * _width);
			var yy = Std.int(((2.0 - d[1]) / 2.0) * _height);
			var xxNext = Std.int((e[0] / maxWValue) * _width);
			var ww = Std.int( xxNext - xx );
			var hh = Std.int( _height - yy );
			var bit = new FlxSprite(xx, yy).makeGraphic(ww, hh, FlxColor.LIME);
			add(bit);
		}

		var outline = new FlxSprite(0, 0).makeGraphic(Std.int(_width), Std.int(_height), FlxColor.TRANSPARENT);
		add(outline);
		FlxSpriteUtil.drawRect(outline, 0, 0, _width, _height, FlxColor.TRANSPARENT, {thickness: 2, color: FlxColor.BLACK});
	}
}