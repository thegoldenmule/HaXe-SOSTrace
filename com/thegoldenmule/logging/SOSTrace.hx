package com.thegoldenmule.logging;

import haxe.Log;
import haxe.PosInfos;
import haxe.Timer;

#if js
	import js.SWFObject;
#end

typedef SOSSocket =
	#if flash9
		flash.net.XMLSocket
	#elseif flash
		flash.XMLSocket
	#elseif js
		js.XMLSocket
	#else
		Dynamic
	#end

/**
 * SOS socket server trace target.
 * 
 * @author thegoldenmule
 */

class SOSTrace {
	
	private var _socket:SOSSocket;
	private var _server:String;
	private var _port:Int;
	private var _history:Array<Dynamic>;
	private var _connected:Bool;
	
	public static inline var DEBUG:String = "debug";
	public static inline var INFO:String = "info";
	public static inline var WARN:String = "warn";
	public static inline var ERROR:String = "error";
	public static inline var FATAL:String = "fatal";
	
	public function new(server:String = "localhost", port:Int = 4444) {
		_server = server;
		_port = port;
		_history = new Array<Dynamic>();
		_connected = false;
		
		// check platform
		#if js
			var swfo:SWFObject = new SWFObject("flashsocket.swf", "flashsocket", 1, 1, "9", "#ffffff"); 
			swfo.addParam("allowScriptAccess", "always"); 
			swfo.write("flashcontent");
			Timer.delay(connect, 500);
		#else
			connect();
		#end
		
		// set trace
		Log.trace = sostrace;
	}
	
	private function connect():Void {
		#if js
			_socket = new SOSSocket("flashsocket");
			_socket.onConnect = onConnect;
		#else
			_socket = new SOSSocket();
			_connected = true;
		#end
		
		_socket.connect(_server, _port);
	}
	
	private function onConnect(b:Bool):Void {
		_connected = true;
		_socket.send("!SOS<showMessage key='debug'>SOS Connection established.</showMessage>\n");
		
		var obj:Dynamic;
		for (obj in _history) {
			send(obj);
		}
	}
	
	private function sostrace(v:Dynamic, ?inf:PosInfos) {
		var logObj:Dynamic = {
			message:Std.string(v),
			parameters:inf,
			logLevel:(null != inf.customParams && inf.customParams.length > 0) ? inf.customParams[0] : "debug",
			tokens:(null != inf.customParams && inf.customParams.length > 1) ? inf.customParams.slice(1) : []
		};
		
		if (_connected) {
			send(logObj);
		} else {
			_history.push(logObj);
		}
	}
	
	private function send(log:Dynamic):Void {
		var message:String = substitute(log.message, log.tokens);
		_socket.send("!SOS"
			+ "<showMessage key='" + log.logLevel + "'>"
			+ log.parameters.className + ":" + log.parameters.methodName + ":" + log.parameters.lineNumber + "  "
			+ message
			+ "</showMessage>"
			+ "\n");
	}
	
	private static function substitute(str:String, params:Array<String>):String {
		if (null == str) {
			return "";
		}
		
		// Replace all of the parameters in the msg string.
		var i:Int = 0;
		for (i in 0...params.length){
			var regex:EReg = new EReg("\\{" + i + "\\}", "g");
			str = regex.replace(str, params[i]);
		}
		
		return str;
	}
}