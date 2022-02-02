package;

import flixel.input.gamepad.FlxGamepad;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.transition.FlxTransitionableState;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.group.FlxGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.net.curl.CURLCode;

#if desktop
import Discord.DiscordClient;
#end

using StringTools;

typedef CreditsObject =
{
	var leftLine:FlxText;
	var rightLine:FlxText;
	var isHyperlink:Bool;
	var hyperlink:String;
}

class CreditsState extends MusicBeatState
{
	var movedBack:Bool = false;
	var credObjects:Array<CreditsObject> = [];

	override function create()
	{
		var menuBG:FlxSprite = new FlxSprite().loadGraphic(Paths.image("menuDesat"));

		menuBG.color = 0xFF71FDB2;
		menuBG.setGraphicSize(Std.int(menuBG.width * 1.1));
		menuBG.updateHitbox();
		menuBG.screenCenter();
		menuBG.antialiasing = FlxG.save.data.antialiasing;
		add(menuBG);

		var textB1 = [];
		var textB2 = [];
		var textB3 = [];

		var textBlocks:Array<String> = CoolUtil.coolTextFile(Paths.txt('data/credits'));

		for (i in 0...textBlocks.length)
		{
			var textSplit = textBlocks[i].split("|");
			textB1.push(textSplit[0]);
			if (textSplit.length > 2)
				textB3.push(textSplit[2]);
			else
				textB3.push("");

			if (textSplit.length > 1)
				textB2.push(textSplit[1]);
			else
				textB2.push("");
		}

		var txtY = 80;
		credObjects = [];

		for (i in 0...textB1.length)
		{
			var newCredObject:CreditsObject = {leftLine: null, rightLine: null, isHyperlink: false, hyperlink: ''};
			var textLine1 = new FlxText(50, txtY, 0, textB1[i], 48);
			textLine1.setFormat("VCR OSD Mono", 36);
			textLine1.alignment = FlxTextAlign.LEFT;
			textLine1.borderColor = FlxColor.BLACK;
			textLine1.borderStyle = FlxTextBorderStyle.OUTLINE;
			newCredObject.leftLine = textLine1;
			add(textLine1);

			if (textB3[i] != "")
			{
				newCredObject.isHyperlink = true;
				newCredObject.hyperlink = textB3[i];
				textLine1.color = 0xFFC0FFFF;
			}

			var textLine2 = new FlxText(1230, txtY, 0, textB2[i], 48);
			textLine2.setFormat("VCR OSD Mono", 36);
			textLine2.alignment = FlxTextAlign.RIGHT;
			textLine2.x -= textLine2.width;
			textLine2.borderColor = FlxColor.BLACK;
			textLine2.borderStyle = FlxTextBorderStyle.OUTLINE;
			newCredObject.rightLine = textLine2;
			add(textLine2);
			txtY += Std.int(Math.max(32, Math.max(textLine1.height, textLine2.height)));

			credObjects.push(newCredObject);
		}

		FlxG.mouse.visible = true;

		super.create();
	}

	override function update(elapsed:Float)
	{
		for (cred in credObjects)
		{
			if (cred.isHyperlink)
			{
				if (FlxG.mouse.overlaps(cred.leftLine))
				{
					cred.leftLine.color = 0xFF00C0FF;
					if (FlxG.mouse.justPressed)
						fancyOpenURL(cred.hyperlink);
				}
				else
					cred.leftLine.color = 0xFFC0FFFF;
			}
		}

		if (controls.BACK && !movedBack)
		{
			FlxG.mouse.visible = false;
			FlxG.sound.play(Paths.sound('cancelMenu'));
			movedBack = true;
			FlxG.switchState(new MainMenuState());
		}

		super.update(elapsed);
	}
}
