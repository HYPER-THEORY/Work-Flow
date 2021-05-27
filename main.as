import flash.text.TextField;
import flash.events.Event;
import flash.events.MouseEvent;
import flash.net.SharedObject;
import flash.net.FileReference;
import flash.display.MovieClip;
import flash.geom.Rectangle;
import flash.geom.Point;
import flash.utils.ByteArray;

const REPORTER : Array = ["Today you have \n worked for ", "h ", "m ", "s"];

const ALPHA_DECAY : Number = 0.2;

const RESPOND_ZONE : Rectangle = new Rectangle(30, 110, 120, 40);

const EVENT_ZONE : Array = [-52.5, -17.5, 17.5, 52.5];

const EVENT_POSITION : Array = [-35, 0, 35];

const RESUME_VELOCITY : Number = 0.2;

var textHour1 : TextField = hour1;
var textHour2 : TextField = hour2;
var textWorktime : TextField = worktime;

var comInteract : MovieClip = interact;
var btnCircle : MovieClip = comInteract.circle;

var save : SharedObject = SharedObject.getLocal("workflow");
var saveList : Array;
var saveObject : Object;

var timestamp : int = 0;

var totalTime : Number = 0;
var lastTime : Number = new Date().getTime();
var lastTotalTime : Number = 0;

var isInteract : Boolean = false;
var isDrag : Boolean = false;

var alphaI : Number = -1;

var eventType : int = 1;

var updateEvent : Object = {
	
	events : [
	
		function(d : Date) : void {
			
			var csv : String = "";
			for (var i : int = 0; i < saveList.length; ++i)
				csv += saveList[i].timestamp + "," + ((int) (saveList[i].worktime)) + "\n";
			
			var bytes : ByteArray = new ByteArray;
			bytes.writeUTFBytes(csv);
			
			var target : FileReference = new FileReference();
			target.save(bytes, "workflow.csv");
			
			eventType = 1;
			updateEvent.current = updateEvent.events[1];
		},
		
		function(d : Date) : void {
			
			totalTime = (d.getTime() - lastTime) / 1000 + lastTotalTime;
		},
		
		function(d : Date) : void {
			
			lastTotalTime = totalTime;
			lastTime = d.getTime();
		}
	],
	
	current : Function
};

function getTimestamp(d : Date) : int {
	
	return d.fullYear * 10000 + (d.month + 1) * 100 + d.date;
}

function getTimes(t : Number) : Object {
	
	return {
		hour : (int) (t / 3600),
		minute : (int) (t / 60 % 60),
		second : (int) (t % 60)
	};
}

function update(e : Event) : void {
	
	var date : Date = new Date();
	
	updateEvent.current(date);
	
	timestamp = getTimestamp(date);
	
	if (saveObject.timestamp != timestamp) {
		
		saveList.push({
			timestamp : timestamp,
			worktime : 0
		});
		
		saveObject = saveList[saveList.length - 1];
		
		totalTime = 0;
		lastTime = date.getTime();
		lastTotalTime = 0;
	}
	
	saveObject.worktime = totalTime;
	
	var times : Object = getTimes(totalTime);
	
	textHour1.text = ((int) (times.hour / 10)).toString();
	textHour2.text = ((int) (times.hour % 10)).toString();
	
	textWorktime.htmlText = REPORTER[0] + times.hour + REPORTER[1] + times.minute + REPORTER[2] + times.second + REPORTER[3];
	
	if (isInteract && (!RESPOND_ZONE.contains(mouseX, mouseY))) {
		isInteract = false;
		droped();
	}
	
	if (isInteract && alphaI < 1) alphaI += ALPHA_DECAY;
	else if ((!isInteract) && alphaI > -1) alphaI -= ALPHA_DECAY;
	
	textWorktime.alpha = -alphaI;
	comInteract.alpha = alphaI;
	
	if (isDrag) {
		
		var circleX : Number = comInteract.mouseX;
		
		btnCircle.x = circleX;
		
		if (circleX < EVENT_ZONE[0] || circleX > EVENT_ZONE[3])
			droped();
		
		if (circleX < EVENT_ZONE[1])
			eventType = 0;
		else if (circleX < EVENT_ZONE[2])
			eventType = 1;
		else
			eventType = 2;
	} else {
		
		btnCircle.x += (EVENT_POSITION[eventType] - btnCircle.x) * RESUME_VELOCITY;
	}
}

function mousemoved(e : Event) : void {
	
	if ((!isInteract) && RESPOND_ZONE.contains(mouseX, mouseY))
		isInteract = true;
}

function mousepressed(e : Event) : void {
	
	if (Point.distance(new Point(comInteract.mouseX, comInteract.mouseY), new Point(btnCircle.x, btnCircle.y)) <= btnCircle.width / 2)
		isDrag = true;
}

function mousereleased(e : Event) : void {
	
	droped();
}

function droped() : void {
	
	isDrag = false;
	
	updateEvent.current = updateEvent.events[eventType];
}

updateEvent.current = updateEvent.events[1];

timestamp = getTimestamp(new Date());

if (save.data.list == undefined) {
	save.data.list = [{
		timestamp : timestamp,
		worktime : 0
	}];
}

saveList = save.data.list;

saveObject = saveList[saveList.length - 1];

lastTotalTime = saveObject.worktime;

addEventListener(Event.ENTER_FRAME, update);

addEventListener(MouseEvent.MOUSE_MOVE, mousemoved);

addEventListener(MouseEvent.MOUSE_DOWN, mousepressed);

addEventListener(MouseEvent.MOUSE_UP, mousereleased);
