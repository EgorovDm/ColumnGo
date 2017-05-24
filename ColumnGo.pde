// start OSC config
import controlP5.*;
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
ControlP5 cp5;
OscP5 oscP5;
Textlabel columnNum;
Textlabel deckNum;
NetAddress myRemoteLocation;
OscBundle myBundle;
OscMessage myMessage;
int column = 0;
int deck = 1;
Pattern p_col = Pattern.compile("^/track([0-9]+)/select$");
Pattern p_deck = Pattern.compile("^/composition/deck([0-9]+)/select$");
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
	//setup UI
	cp5 = new ControlP5(this);
	//Next column BTN
	cp5.addButton("next_col")
		.setPosition(int(2*glob_width/3), int(glob_height/3 + 1))
		.setSize(int(glob_width/3), int(2*glob_height/3));
	//Prev colomn BTN
	cp5.addButton("prev_col")
		.setPosition(1, int(glob_height/3 + 1))
		.setSize(int(glob_width/3), int(2*glob_height/3));
	//Next deck BTN
	cp5.addButton("next_deck")
		.setPosition(int(2*glob_width/3), 0)
		.setSize(int(glob_width/3), int(glob_height/3));
	//Prev deck BTN
	cp5.addButton("prev_deck")
		.setPosition(1, 0)
		.setSize(int(glob_width/3), int(glob_height/3));
	//Labels
	columnNum = cp5.addTextlabel("colNum")
					.setText("-init-")
					.setFont(createFont("Arial",int(glob_height*0.2)))
					.setPosition(int(glob_width*0.45), int(glob_height*.55));
	deckNum = cp5.addTextlabel("deckNum")
					.setText("-init-")
					.setFont(createFont("Arial",int(glob_height*0.2)))
					.setPosition(int(glob_width*0.45), int(glob_height*0.05));
	//Inet stuff
	myRemoteLocation = new NetAddress(dst_ip, port_out);  
	myBundle = new OscBundle();
	myMessage = new OscMessage("/");  
}


void draw() {
	//Update lables
	columnNum.setText(str(column));
	deckNum.setText(str(deck));
	//if we lose focus, draw red
	if(!focused) {
		background(220,32,32);
	} else {
		background(0,0,32);
	}
}

//controller block
//++++++++++++++++++++++++
public void next_col() {
	column++;
	send_col();
}

public void prev_col() {
	column--;
	send_col();
}

public void next_deck() {
	deck++;
	column = 0;
	send_deck();
}

public void prev_deck() {
	deck--;
	column = 0;
	send_deck();
}
//++++++++++++++++++++++++

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
			case '{':
				deck--;
				column = 0;
				send_deck();
				break;
			case '}':
				deck++;
				column = 0;
				send_deck();
				break;
			}
	}
}


void send_col() {
	//limit column numbers
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


void send_deck() {
	//limit deck numbers
	deck = constrain(deck, 1, 99);
	String address = ("/composition/deck"+deck+"/select");
	myMessage.setAddrPattern(address);
	myMessage.add(1);
	myBundle.add(myMessage);
	myMessage.clear();
	oscP5.send(myBundle, myRemoteLocation); 
	myBundle.clear();
}


void oscEvent(OscMessage theOscMessage) {
	String oscMsg = theOscMessage.addrPattern();
	Matcher m_col = p_col.matcher(oscMsg);
	Matcher m_deck = p_deck.matcher(oscMsg);
	if (m_col.matches()) {
		column = Integer.parseInt(m_col.group(1));
	}
	if (m_deck.matches()) {
		deck = Integer.parseInt(m_col.group(1));
	}
	if(theOscMessage.addrPattern().equals("/composition/disconnectall"))
		column = 0;
}