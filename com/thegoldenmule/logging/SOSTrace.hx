package com.thegoldenmule.logging;

import flash.errors.Error;
import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.SecurityErrorEvent;
import flash.net.XMLSocket;
import haxe.Log;
import haxe.PosInfos;

/**
 * SOS socket server trace target.
 * 
 * @author thegoldenmule
 */
class SOSTrace {
	
	private var _socket:XMLSocket;
	private var _server:String;
	private var _port:Int;
	private var _history:Array<Dynamic>;
	
	public static inline var DEBUG:String = "debug";
	public static inline var INFO:String = "info";
	public static inline var WARN:String = "warn";
	public static inline var ERROR:String = "error";
	public static inline var FATAL:String = "fatal";
	
	public function new(server:String = "localhost", port:Int = 4444) {
		_socket = new XMLSocket();
		_server = server;
		_port = port;
		_history = new Array<Dynamic>();
		
		Log.trace = sostrace;
	}
	
	private function sostrace(v:Dynamic, ?inf:PosInfos) {
		if (null == _socket) return;
		
		var logObj:Dynamic = {
			message:Std.string(v),
			parameters:inf,
			logLevel:(null != inf.customParams && inf.customParams.length > 0) ? inf.customParams[0] : "debug",
			tokens:(null != inf.customParams && inf.customParams.length > 1) ? inf.customParams.slice(1) : []
		};
		
		if (_socket.connected) {
			send(logObj);
			return;
		} else if (!_socket.hasEventListener(Event.CONNECT)) {
			_socket.addEventListener(IOErrorEvent.IO_ERROR, errorHandler, false, 0, true);
			_socket.addEventListener(SecurityErrorEvent.SECURITY_ERROR, errorHandler, false, 0, true);
			_socket.addEventListener(Event.CONNECT, connectHandler, false, 0, true);
			_socket.connect(_server, _port);
			
		}
		
		_history.push(logObj);
	}
	
	private function connectHandler(event:Event):Void {
		// send all items in history
		var log:Dynamic;
		for (log in _history) {
			send(log);
		}
		
		_history = [];
	}
	
	private function errorHandler(event:Event):Void {
		_socket = null;
		_history = [];
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