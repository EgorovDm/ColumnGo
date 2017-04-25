// start OSC config
import oscP5.*;
import netP5.*;
import java.util.regex.*;
import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.util.Properties;
import java.awt.event.KeyEvent;

//Settings variebles
// - - - - - - - - - - - - - - - 
int glob_width;
int glob_height;
int port_in; 
int port_out;
String dst_ip;
Integer fps;
// - - - - - - - - - - - - - - - 

//Service staff
//==============================
OscP5 oscP5;
NetAddress myRemoteLocation;
OscBundle myBundle;
OscMessage myMessage;
int column = 0;
//==============================

void settings() {
	//read settings
	Properties prop = new Properties();
	InputStream input = null;
	try {
		input = new FileInputStream(dataFile("config.properties"));
		// load a properties file
		prop.load(input);
		glob_width = Integer.parseInt(prop.getProperty("ui_width"));
		glob_height = Integer.parseInt(prop.getProperty("ui_height"));
		port_in = Integer.parseInt(prop.getProperty("port_in"));
		port_out = Integer.parseInt(prop.getProperty("port_out"));
		dst_ip = prop.getProperty("dst_ip");
		fps = Integer.parseInt(prop.getProperty("fps_rate"));
	} catch (IOException ex) {
		ex.printStackTrace();
	} finally {
		if (input != null) {
			try {
				input.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	size(glob_width, glob_height);
}


void setup() {
	surface.setAlwaysOnTop(true);
	//setup OSC communication
	oscP5 = new OscP5(this,port_in);
	myRemoteLocation = new NetAddress(dst_ip, port_out);  
	myBundle = new OscBundle();
	myMessage = new OscMessage("/");  
}


void draw() {
	//limit column to max numbers
	background(32);
	fill(64,64,64);
	noStroke();
	rect(width/2, 0, width/2, height);
	stroke(255);
	//if we lose focus, draw red
	if(!focused) {
		fill(255,0,0,200);
		noStroke();
		rect(0,0,width,height);
	}
	noStroke();
	fill(128,128);
	rect(width/2 - 30 ,height/2 - 20, 60, 40);
	fill(255,255);
	textSize(25);
	if (column <10 ) {
		text(str(column), width/2 - 8, height/2 + 8);
	} else {
		text(str(column), width/2 - 15, height/2 + 8);
	}
	
}


void mouseReleased() {
	if(mouseX > width/2) {
		column++;
	} else {
		column--;
	}
	send_col();
}


void keyPressed() {
	if (key == CODED) {
		switch(keyCode) {
		case KeyEvent.VK_PAGE_UP: 
			column--;
			send_col();
			break;
		case KeyEvent.VK_PAGE_DOWN:
			column++;
			send_col(); 
			break;
		}
	} else {
		switch(key) {
			case ']': 
				column++;
				send_col();
				break;
			case ' ': 
				column++;
				send_col();
				break;
			case '[':
				column--;
				send_col(); 
				break;
			}
	}
}


void send_col() {
	column = constrain(column, 0, 99);
	String address = ("/track"+column+"/connect/");
	if(column == 0){
		address = ("/composition/disconnectall");
	}
	myMessage.setAddrPattern(address);
	myMessage.add(1);
	myBundle.add(myMessage);
	myMessage.clear();
	oscP5.send(myBundle, myRemoteLocation); 
	myBundle.clear();
}


void oscEvent(OscMessage theOscMessage) {
	String oscMsg = theOscMessage.addrPattern();
	Pattern p_col = Pattern.compile("^/track([0-9]+)/select$");
	Matcher m_col = p_col.matcher(oscMsg);
	if (m_col.matches()) {
		column = Integer.parseInt(m_col.group(1));
	}
	if(theOscMessage.addrPattern().equals("/composition/disconnectall"))
		column = 0;
}