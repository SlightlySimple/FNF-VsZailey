package;

#if FEATURE_STEPMANIA
import smTools.SMFile;
#end
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.FlxState;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionSprite.GraphicTransTileDiamond;
import flixel.addons.transition.FlxTransitionableState;
import flixel.addons.transition.TransitionData;
import flixel.graphics.FlxGraphic;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup;
import flixel.input.gamepad.FlxGamepad;
import flixel.math.FlxPoint;
import flixel.math.FlxRect;
import flixel.system.FlxSound;
import flixel.system.ui.FlxSoundTray;
import flixel.text.FlxText;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import flixel.util.FlxTimer;
import lime.app.Application;
import openfl.Assets;
import flixel.input.keyboard.FlxKey;

using StringTools;

typedef TitleScreenSprite =
{
	var sprite:FlxSprite;
	var animations:Array<String>;
}

typedef TitleScreenAnim =
{
	var name:String;
	var animName:String;
	var fps:Int;
	var loop:Bool;
	var indices:Array<Int>;
}

typedef TitleScreenPiece =
{
	var type:String;
	var id:String;
	var image:String;
	var position:Array<Int>;
	var scale:Array<Float>;
	var finalPosition:Array<Int>;
	var animations:Array<TitleScreenAnim>;
	var sizes:Array<Float>;
}

typedef TitleScreenSequence =
{
	var type:String;
	var text:Array<String>;
}

typedef TitleScreenData =
{
	var bpm:Int;
	var backgroundColor:String;
	var seqBackgroundColor:String;
	var startingSequence:Array<TitleScreenSequence>;
	var pieces:Array<TitleScreenPiece>;
}

class TitleState extends MusicBeatState
{
	static var initialized:Bool = false;

	var blackScreen:FlxSprite;
	var credGroup:FlxGroup;
	var credTextShit:Alphabet;
	var textGroup:FlxGroup;
	var myData:TitleScreenData;

	var curWacky:Array<String> = [];

	override public function create():Void
	{
		@:privateAccess
		{
			Debug.logTrace("We loaded " + openfl.Assets.getLibrary("default").assetsLoaded + " assets into the default library");
		}

		FlxG.autoPause = false;

		FlxG.save.bind('funkin', 'ninjamuffin99');

		PlayerSettings.init();

		KadeEngineData.initSave();

		// It doesn't reupdate the list before u restart rn lmao
		NoteskinHelpers.updateNoteskins();

		FlxG.sound.muteKeys = [FlxKey.fromString(FlxG.save.data.muteBind)];
		FlxG.sound.volumeDownKeys = [FlxKey.fromString(FlxG.save.data.volDownBind)];
		FlxG.sound.volumeUpKeys = [FlxKey.fromString(FlxG.save.data.volUpBind)];

		FlxG.mouse.visible = false;

		FlxG.worldBounds.set(0, 0);

		FlxGraphic.defaultPersist = FlxG.save.data.cacheImages;

		MusicBeatState.initSave = true;

		fullscreenBind = FlxKey.fromString(FlxG.save.data.fullscreenBind);

		Highscore.load();

		myData = cast Paths.loadJSON('titleScreen');

		curWacky = FlxG.random.getObject(getIntroTextShit());

		trace('hello');

		// DEBUG BULLSHIT

		super.create();

		#if FREEPLAY
		FlxG.switchState(new FreeplayState());
		clean();
		#elseif CHARTING
		FlxG.switchState(new ChartingState());
		clean();
		#else
		#if !cpp
		new FlxTimer().start(1, function(tmr:FlxTimer)
		{
			startIntro();
		});
		#else
		startIntro();
		#end
		#end
	}

	var titleScreenSprites:Map<String, TitleScreenSprite> = [];

	function startIntro()
	{
		persistentUpdate = true;
		Paths.setCurrentLevel("week0");			// Doing this because there has to be some path in order for the shared folder to get checked automatically

		var bg:FlxSprite = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromString(myData.backgroundColor));
		add(bg);

		for (i in myData.pieces)
		{
			if (i.id == null)
				i.id = i.image;

			if (i.type == 'static' || i.type == 'logo')
			{
				var piece:FlxSprite = new FlxSprite(i.position[0], i.position[1]).loadGraphic(Paths.image(i.image));
				piece.antialiasing = FlxG.save.data.antialiasing;
				if (i.scale != null && i.scale.length == 2)
				{
					piece.scale.x = i.scale[0];
					piece.scale.y = i.scale[1];
				}
				titleScreenSprites[i.id] = {sprite: piece, animations: []};
				add(piece);
			}
			else
			{
				var piece:FlxSprite = new FlxSprite(i.position[0], i.position[1]);
				piece.frames = Paths.getSparrowAtlas(i.image);
				var pieceData:TitleScreenSprite = {sprite: piece, animations: []};
				for (j in i.animations)
				{
					if (j.indices != null && j.indices.length > 0)
						piece.animation.addByIndices(j.name, j.animName, j.indices, "", j.fps, j.loop);
					else
						piece.animation.addByPrefix(j.name, j.animName, j.fps, j.loop);
					pieceData.animations.push(j.name);
				}

				piece.animation.play(i.animations[0].name);
				piece.antialiasing = FlxG.save.data.antialiasing;
				if (i.scale != null && i.scale.length == 2)
				{
					piece.scale.x = i.scale[0];
					piece.scale.y = i.scale[1];
				}
				titleScreenSprites[i.id] = pieceData;
				add(piece);
			}
		}

		credGroup = new FlxGroup();
		add(credGroup);
		textGroup = new FlxGroup();

		blackScreen = new FlxSprite().makeGraphic(FlxG.width, FlxG.height, FlxColor.fromString(myData.seqBackgroundColor));
		credGroup.add(blackScreen);

		credTextShit = new Alphabet(0, 0, "ninjamuffin99\nPhantomArcade\nkawaisprite\nevilsk8er", true);
		credTextShit.screenCenter();

		// credTextShit.alignment = CENTER;

		credTextShit.visible = false;

		FlxTween.tween(credTextShit, {y: credTextShit.y + 20}, 2.9, {ease: FlxEase.quadInOut, type: PINGPONG});

		FlxG.mouse.visible = false;

		if (initialized)
			skipIntro(false);
		else
		{
			var diamond:FlxGraphic = FlxGraphic.fromClass(GraphicTransTileDiamond);
			diamond.persist = true;
			diamond.destroyOnNoUse = false;

			FlxTransitionableState.defaultTransIn = new TransitionData(FADE, FlxColor.BLACK, 1, new FlxPoint(0, -1), {asset: diamond, width: 32, height: 32},
				new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));
			FlxTransitionableState.defaultTransOut = new TransitionData(FADE, FlxColor.BLACK, 0.7, new FlxPoint(0, 1),
				{asset: diamond, width: 32, height: 32}, new FlxRect(-200, -200, FlxG.width * 1.4, FlxG.height * 1.4));

			transIn = FlxTransitionableState.defaultTransIn;
			transOut = FlxTransitionableState.defaultTransOut;

			// HAD TO MODIFY SOME BACKEND SHIT
			// IF THIS PR IS HERE IF ITS ACCEPTED UR GOOD TO GO
			// https://github.com/HaxeFlixel/flixel-addons/pull/348

			// var music:FlxSound = new FlxSound();
			// music.loadStream(Paths.music('freakyMenu'));
			// FlxG.sound.list.add(music);
			// music.play();
			FlxG.sound.playMusic(Paths.music('freakyMenu'), 0);

			FlxG.sound.music.fadeIn(4, 0, 0.7);
			Conductor.changeBPM(myData.bpm);
			initialized = true;
		}

		// credGroup.add(credTextShit);
	}

	function getIntroTextShit():Array<Array<String>>
	{
		var fullText:String = Assets.getText(Paths.txt('data/introText'));

		var firstArray:Array<String> = fullText.split('\n');
		var swagGoodArray:Array<Array<String>> = [];

		for (i in firstArray)
		{
			swagGoodArray.push(i.split('--'));
		}

		return swagGoodArray;
	}

	var transitioning:Bool = false;
	var fullscreenBind:FlxKey;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music != null)
			Conductor.songPosition = FlxG.sound.music.time;

		if (FlxG.keys.anyJustPressed([fullscreenBind]))
		{
			FlxG.fullscreen = !FlxG.fullscreen;
		}

		var pressedEnter:Bool = controls.ACCEPT;

		#if mobile
		for (touch in FlxG.touches.list)
		{
			if (touch.justPressed)
			{
				pressedEnter = true;
			}
		}
		#end

		if (pressedEnter && !transitioning && skippedIntro)
		{
			if (FlxG.save.data.flashing)
			{
				for (i in myData.pieces)
				{
					if (i.type == 'pressEnter')
					{
						var piece:FlxSprite = titleScreenSprites[i.id].sprite;
						piece.animation.play(titleScreenSprites[i.id].animations[1]);
					}
				}
			}

			FlxG.camera.flash(FlxColor.WHITE, 1);
			FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);

			transitioning = true;
			// FlxG.sound.music.stop();

			MainMenuState.firstStart = true;
			MainMenuState.finishedFunnyMove = false;

			new FlxTimer().start(2, function(tmr:FlxTimer)
			{
				FlxG.switchState(new MainMenuState());
				clean();
			});
		}

		if (pressedEnter && !skippedIntro && initialized)
		{
			skipIntro();
		}

		super.update(elapsed);
	}

	function createCoolText(textArray:Array<String>)
	{
		for (i in 0...textArray.length)
		{
			var money:Alphabet = new Alphabet(0, 0, textArray[i], true, false);
			money.screenCenter(X);
			money.y += (i * 60) + 200;
			credGroup.add(money);
			textGroup.add(money);
		}
	}

	function addMoreText(text:String)
	{
		var coolText:Alphabet = new Alphabet(0, 0, text, true, false);
		coolText.screenCenter(X);
		coolText.y += (textGroup.length * 60) + 200;
		credGroup.add(coolText);
		textGroup.add(coolText);
	}

	function deleteCoolText()
	{
		while (textGroup.members.length > 0)
		{
			credGroup.remove(textGroup.members[0], true);
			textGroup.remove(textGroup.members[0], true);
		}
	}

	override function beatHit()
	{
		super.beatHit();

		for (i in myData.pieces)
		{
			if (i.type == 'animateOnBeat')
			{
				var desiredAnim = curBeat % titleScreenSprites[i.id].animations.length;
				var piece:FlxSprite = titleScreenSprites[i.id].sprite;
				piece.animation.play(titleScreenSprites[i.id].animations[desiredAnim], true);
			}
			else if (i.type == 'logo')
			{
				var piece:FlxSprite = titleScreenSprites[i.id].sprite;
				piece.scale.x = i.sizes[0];
				piece.scale.y = i.sizes[0];
				new FlxTimer().start(0.05, function(tmr:FlxTimer)
				{
					piece.scale.x = i.sizes[2];
					piece.scale.y = i.sizes[2];
					FlxTween.tween(piece.scale, {x: i.sizes[1], y: i.sizes[1]}, 0.15, {ease: FlxEase.quadOut});
				});
			}
		}

		if ( curBeat < myData.startingSequence.length )
		{
			var mySeq = myData.startingSequence[curBeat];
			switch (mySeq.type)
			{
				case 'addMoreText':
					for (t in mySeq.text)
					{
						if (t == 'curWacky0')
							addMoreText(curWacky[0]);
						else if (t == 'curWacky1')
							addMoreText(curWacky[1]);
						else
							addMoreText(t);
					}
				case 'deleteCoolText':
					deleteCoolText();
				case 'refreshWacky':
					curWacky = FlxG.random.getObject(getIntroTextShit());
				case 'skipIntro':
					skipIntro();
			}
		}
	}

	var skippedIntro:Bool = false;

	function skipIntro(?doBeatDrop:Bool = true):Void
	{
		if (!skippedIntro)
		{
			Debug.logInfo("Skipping intro...");

			FlxG.camera.flash(FlxColor.WHITE, 4);
			remove(credGroup);

			for (i in myData.pieces)
			{
				if (i.type == 'logo')
				{
					var piece:FlxSprite = titleScreenSprites[i.id].sprite;
					FlxTween.tween(piece, {x: i.finalPosition[0], y: i.finalPosition[1]}, 1.4, {ease: FlxEase.expoInOut});

					piece.angle = -4;

					new FlxTimer().start(0.01, function(tmr:FlxTimer)
					{
						if (piece.angle == -4) 
							FlxTween.angle(piece, piece.angle, 4, 4, {ease: FlxEase.quartInOut});
						if (piece.angle == 4) 
							FlxTween.angle(piece, piece.angle, -4, 4, {ease: FlxEase.quartInOut});
					}, 0);
				}
			}

			// It always bugged me that it didn't do this before.
			// Skip ahead in the song to the drop.
			var intendedMusicTime = ( ( myData.startingSequence.length - 1 ) / ( myData.bpm / 60 ) ) * 1000;
			if ( Math.abs( intendedMusicTime - FlxG.sound.music.time ) > 50 && doBeatDrop )
				FlxG.sound.music.time = intendedMusicTime;			// so there's no weird sound issues when the intro ISN'T skipped

			skippedIntro = true;
		}
	}
}
