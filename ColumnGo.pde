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
int layer_num;
String[] dst_ip;
Integer fps;
// - - - - - - - - - - - - - - - 

//Service staff
//==============================
ControlP5 cp5;
OscP5 oscP5;
Textlabel columnNum;
Textlabel deckNum;
NetAddress[] myRemoteLocations;
OscBundle myBundle;
OscMessage myMessage;
int column = 0;
int deck = 1;
int t = 0;
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
		layer_num = Integer.parseInt(prop.getProperty("layer_num"));
		dst_ip = prop.getProperty("dst_ip").split(";");
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
	//Inet stuff
	myRemoteLocations = new NetAddress[dst_ip.length];
	for (int i = 0; i < dst_ip.length; i++){
		myRemoteLocations[i] = new NetAddress(dst_ip[i], port_out);
	}
	myBundle = new OscBundle();
	myMessage = new OscMessage("/"); 
	//setup UI
	cp5 = new ControlP5(this);
	ui_set(cp5);
}


void ui_set(ControlP5 cp5o) {
		//Next column BTN
	cp5o.addButton("next_col")
		.setPosition(int(2*width/3), int(height/3 + 1))
		.setSize(int(width/3), int(height/3));
	//Prev colomn BTN
	cp5o.addButton("prev_col")
		.setPosition(1, int(height/3 + 1))
		.setSize(int(width/3), int(height/3));
	//Next deck BTN
	cp5o.addButton("next_deck")
		.setPosition(int(2*width/3), 0)
		.setSize(int(width/3), int(height/3));
	//Prev deck BTN
	cp5o.addButton("prev_deck")
		.setPosition(1, 0)
		.setSize(int(width/3), int(height/3));
	//Transition time slider
	cp5o.addSlider("t_slide")
		.setPosition(1, int(2*height/3 + 2))
		.setSize(width - 2, height/3 - 2)
		.setRange(0,10)
		.setValue(0);
	//Labels
	columnNum = cp5o.addTextlabel("colNum")
					.setText("-init-")
					.setFont(createFont("Arial",int(glob_height*0.2)))
					.setPosition(int(glob_width*0.45), int(glob_height*.35));
	deckNum = cp5o.addTextlabel("deckNum")
					.setText("-init-")
					.setFont(createFont("Arial",int(glob_height*0.2)))
					.setPosition(int(glob_width*0.45), int(glob_height*0.05));
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
			case '0': 
				t = 0;
				upd_slider();
				send_t();
				break;
			case '1': 
				t = 1;
				upd_slider();
				send_t();
				break;
			case '2': 
				t = 2;
				upd_slider();
				send_t();
				break;
			case '3': 
				t = 3;
				upd_slider();
				send_t();
				break;
			case '4': 
				t = 4;
				upd_slider();
				send_t();
				break;
			case '5': 
				t = 5;
				upd_slider();
				send_t();
				break;
			case '6': 
				t = 6;
				upd_slider();
				send_t();
				break;
			case '7': 
				t = 7;
				upd_slider();
				send_t();
				break;
			case '8': 
				t = 8;
				upd_slider();
				send_t();
				break;
			case '9': 
				t = 9;
				upd_slider();
				send_t();
				break;
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


void upd_slider() {
	cp5.getController("t_slide").setValue(t);
}


void t_slide(float f) {
	t = int(f);
	send_t();
}


void send_t() {
	t = constrain(t, 0, 10);
	for (int j = 0; j <= layer_num; j++) {
		String address = ("/layer"+j+"/transitiontime/");
		myMessage.setAddrPattern(address);
		myMessage.add(t/10.0);
		myBundle.add(myMessage);
		myMessage.clear();
		for (int i = 0; i < myRemoteLocations.length; i++) {
			oscP5.send(myBundle, myRemoteLocations[i]);
		}
		myBundle.clear();
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
	for (int i = 0; i < myRemoteLocations.length; i++) {
		oscP5.send(myBundle, myRemoteLocations[i]);
	} 
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
	for (int i = 0; i < myRemoteLocations.length; i++) {
		oscP5.send(myBundle, myRemoteLocations[i]);
	} 
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