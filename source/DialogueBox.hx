package;

import flixel.system.FlxSound;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.text.FlxTypeText;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxSpriteGroup;
import flixel.input.FlxKeyManager;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;

using StringTools;

typedef DialogueSettings =
{
	var textPosition:Array<Int>;
	var textSize:Int;
	var font:String;
	var textColor:String;
	var dropShadowColor:String;
	var dropShadowOffset:Int;
	var dialogueSpeed:Float;
	var p1Offset:Array<Int>;
	var p2Offset:Array<Int>;
	var gfOffset:Array<Int>;
}

class DialogueBox extends FlxSpriteGroup
{
	var box:FlxSprite;

	var curCharacter:String = '';
	var dialogueSettings:DialogueSettings;

	var dialogueList:Array<String> = [];

	// SECOND DIALOGUE FOR THE PIXEL SHIT INSTEAD???
	var swagDialogue:FlxTypeText;

	var dropText:FlxText;
	var skipText:FlxText;

	public var finishThing:Void->Void;

	public function new(talkingRight:Bool = true, ?dialogueList:Array<String>)
	{
		super();

		dialogueSettings = cast Paths.loadJSON('songs/' + PlayState.SONG.songId + '/dialogueSettings');
		cleanDialog();

		box = new FlxSprite(125, 350);
		box.frames = Paths.getSparrowAtlas('speech_bubble_talking');
		box.animation.addByPrefix('normalOpen', 'Speech Bubble Normal Open', 24, false);
		box.animation.addByPrefix('normal', 'speech bubble normal', 24);

		this.dialogueList = dialogueList;

		box.animation.play('normalOpen');
		box.setGraphicSize(Std.int(box.width * 0.9));
		box.updateHitbox();
		add(box);

		if ( curCharacter == 'dad' || curCharacter == PlayState.SONG.player2 )
			box.flipX = true;

		skipText = new FlxText(FlxG.width * 0.8, 10, Std.int(FlxG.width * 0.2), "", 16);
		skipText.font = dialogueSettings.font;
		skipText.color = FlxColor.WHITE;
		skipText.borderColor = FlxColor.BLACK;
		skipText.borderStyle = FlxTextBorderStyle.OUTLINE;
		skipText.text = 'Press backspace to skip';
		add(skipText);

		dropText = new FlxText(dialogueSettings.textPosition[0] + dialogueSettings.dropShadowOffset, dialogueSettings.textPosition[1] + dialogueSettings.dropShadowOffset, Std.int(FlxG.width * 0.6), "", dialogueSettings.textSize);
		dropText.font = dialogueSettings.font;
		dropText.color = FlxColor.fromString(dialogueSettings.dropShadowColor);
		add(dropText);

		swagDialogue = new FlxTypeText(dialogueSettings.textPosition[0], dialogueSettings.textPosition[1], Std.int(FlxG.width * 0.6), "", dialogueSettings.textSize);
		swagDialogue.font = dialogueSettings.font;
		swagDialogue.color = FlxColor.fromString(dialogueSettings.textColor);
		add(swagDialogue);
	}

	var dialogueOpened:Bool = false;
	var dialogueStarted:Bool = false;

	override function update(elapsed:Float)
	{
		dropText.text = swagDialogue.text;

		if (box.animation.curAnim != null)
		{
			if (box.animation.curAnim.name == 'normalOpen' && box.animation.curAnim.finished)
			{
				box.animation.play('normal');
				dialogueOpened = true;
			}
		}

		if (dialogueOpened && !dialogueStarted)
		{
			startDialogue();
			dialogueStarted = true;
		}
		if (PlayerSettings.player1.controls.BACK && isEnding != true)
		{
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			isEnding = true;
			FlxTween.tween(this, {alpha: 0}, 0.7, {
				onComplete: function(twn:FlxTween)
				{
					finishThing();
					kill();
				}
			});
		}
		if (PlayerSettings.player1.controls.ACCEPT && dialogueStarted == true)
		{
			FlxG.sound.play(Paths.sound('clickText'), 0.8);

			if (swagDialogue.text.length >= dialogueList[0].length - 1)
			{
				if (dialogueList[1] == null && dialogueList[0] != null)
				{
					if (!isEnding)
					{
						isEnding = true;
						FlxTween.tween(this, {alpha: 0}, 0.7, {
							onComplete: function(twn:FlxTween)
							{
								finishThing();
								kill();
							}
						});
					}
				}
				else
				{
					dialogueList.remove(dialogueList[0]);
					startDialogue();
				}
			}
			else
				swagDialogue.skip();
		}

		super.update(elapsed);
	}

	var isEnding:Bool = false;

	function startDialogue():Void
	{
		cleanDialog();

		swagDialogue.resetText(dialogueList[0]);
		swagDialogue.sounds = [FlxG.sound.load(Paths.sound(curCharacter + 'Text'), 0.6)];
		swagDialogue.start(dialogueSettings.dialogueSpeed, true);

		// Compiler throws a hissy fit if this is a switch case so :(
		if ( curCharacter == 'dad' || curCharacter == PlayState.SONG.player2 )
		{
			box.flipX = true;
			PlayState.instance.camFollow.setPosition(PlayState.dad.getMidpoint().x + dialogueSettings.p2Offset[0], PlayState.dad.getMidpoint().y + dialogueSettings.p2Offset[1]);
		}
		else if ( curCharacter == 'gf' || curCharacter == PlayState.SONG.gfVersion )
		{
			box.flipX = false;
			PlayState.instance.camFollow.setPosition(PlayState.gf.getMidpoint().x + dialogueSettings.gfOffset[0], PlayState.gf.getMidpoint().y + dialogueSettings.gfOffset[1]);
		}
		else
		{
			box.flipX = false;
			PlayState.instance.camFollow.setPosition(PlayState.boyfriend.getMidpoint().x + dialogueSettings.p1Offset[0], PlayState.boyfriend.getMidpoint().y + dialogueSettings.p1Offset[1]);
		}
	}

	function cleanDialog():Void
	{
		var splitName:Array<String> = dialogueList[0].split(":");
		curCharacter = splitName[1];
		dialogueList[0] = dialogueList[0].substr(splitName[1].length + 2).trim();
	}
}
