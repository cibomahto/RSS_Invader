import com.creatingwithcode.greader.GoogleReaderClient;
import com.creatingwithcode.greader.RecentItemsFeed;
import com.creatingwithcode.greader.FeedItem;

import java.util.regex.*;
import java.util.concurrent.*;

import ddf.minim.*;

AudioPlayer bgmusic;
AudioSample zapSound;
AudioSample enemyExplodeSound;
Minim minim;
PlayerShip ship;

int maxEnemies = 20;
int maxStars = 50;

int textCount  = 0;

float scrollSpeed = 1;

Starfield starfield;

ArrayList enemies;
ArrayList particles;

// Create the object with the run() method
EnemyLoader enemyLoader;
Thread loadThread;

PFont fountainFont;
PFont titleFont;

class EnemyLoader implements Runnable {
  ArrayList working = new ArrayList();    // RSS items that are still loading (image, etc)
  ArrayList ready = new ArrayList();      // RSS items that are ready to go

  // Queue holding the enemies that are ready to shove out the door
  private LinkedBlockingQueue  readyQueue = new LinkedBlockingQueue();


  GoogleReaderClient grc;
  
  public boolean enemyAvailable() {
    return (readyQueue.size() > 0);
  }
  
  public Enemy getNextEnemy() {
    return (Enemy) readyQueue.poll(); 
  }
    
  
  // This method is called when the thread runs
  public void run() {
    // Google reader client bits
    

    // Put your name and password into a text file, that won't be checked in :-)
    String[] credentials = loadStrings("credentials.txt");
    grc = new GoogleReaderClient(credentials[0], credentials[1]);

    // or, replace this with you username/password
//    grc = new GoogleReaderClient("username", "password");

    RecentItemsFeed rif;
    Iterator rifi;

    while(true) {
      // if we've got less than 20 enemies around, look for some more
      // TOOD: only try this once in a while?
      if (working.size() + readyQueue.size() < 10) {
        rif = grc.getRecentItemsFeed();
        rifi = rif.getItems().iterator();
        
        while(rifi.hasNext()){
          FeedItem fi = (FeedItem) rifi.next();
      
          String title = (String) ((fi.getTitle() == null) ? "" :
                                   fi.getTitle());
          
          // Try for a summary first, if it is blank, go for the content
          String summary = (String) ((fi.getSummary() == null) ? "" :
                                     fi.getSummary().get("content"));

          if (summary=="") {                                     
            summary = (String) ((fi.getContent() == null) ? "" :
                                fi.getContent().get("content"));
          }
          
          
          // Content should contain the text blurb and images in an HTML format.
          String description = summary.replaceAll("\\<.*?>","");
          
          // Do a quick&dirty search for an image in the content          
          String imageURL = (summary.replaceAll("\r\n|\r|\n","").replaceFirst(".*?<img.*?src=\"","")).replaceAll("\".*","");
          
          
          if (imageURL.contains(".jpg") || imageURL.contains(".png")) {
//            println(imageURL);
          }
          else {
            println("couldn't find image in: -------------------");
            println(title);
            println("-------------------------------------------");
            println(summary);
            println("-------------------------------------------");
            println(imageURL);
            println("-------------------------------------------");
            imageURL = "";
          }

          // Build a new enemy, and stuff it with our info
          Enemy newEnemy = new Enemy(int(random(width-80)), -60, 0, enemies);
          
          newEnemy.setTitle(title);
          newEnemy.setSummary(description);
          newEnemy.setImageURL(imageURL);
      
//          working.add(newEnemy);

          try{ 
            readyQueue.put(newEnemy);
          } catch( InterruptedException e ) {
            println("Interrupted Exception caught");
          }

        }
      }
      
      try{ 
        Thread.sleep(10);
      } catch( InterruptedException e ) {
        println("Interrupted Exception caught");
      }
      
      // Go through the list of enemies that were still processing, and clear out
      // any that are finished.
      for (int i = working.size() - 1; i >= 0; i--) {
        Enemy enemy = (Enemy) working.get(i);
        
        // If the enemy has finished loading, move it to the ready list
        if( enemy.isLoaded() ) {
          try{ 
            readyQueue.put(enemy);
          } catch( InterruptedException e ) {
            println("Interrupted Exception caught");
          }
          working.remove(i);
        }
      }
    }
  }
}


void setup()
{
  // Video bits
  size(600,800);
  frameRate(30);
  noStroke();
  smooth();

  // font bits
  PFont font;
  // http://www.1001freefonts.com/ComicBookCommando.php
  fountainFont = createFont("Comicv3", 12);
  titleFont = createFont("Comicv3", 64); 
  textFont(fountainFont);

  // Audio bits

  minim = new Minim(this);
  
  // load a file, give the AudioPlayer buffers that are 2048 samples long
  
  // Song is 'Flight of Dragons' by Nintendude: http://8bitcollective.com/members/Nintendude/
  bgmusic = minim.loadFile("flight_of_dragon.mp3", 2048);
  // play the file
  bgmusic.play();

  //sounds from http://www.atomsplitteraudio.com/info.php?id=25
  zapSound = minim.loadSample("Zap FX 007.wav", 2048);

  enemyExplodeSound = minim.loadSample("Noise 002.wav", 2048);

  enemyLoader = new EnemyLoader();
  loadThread = new Thread(enemyLoader);

  loadThread.start();
  
  // Game bits
  starfield = new Starfield();
  enemies = new ArrayList();
  particles = new ArrayList();
  ship = new PlayerShip();

  // show title screen
  particles.add(new textParticle("RSS Invaders", new PVector(100,250), titleFont, new PVector(0,0), new PVector(0,0), 255));
}

void draw()
{
  background(0);
  
  starfield.move();
  starfield.display();

  // do the particles
  for (int i = 0; i < particles.size(); i++) {
    Particle particle = (Particle) particles.get(i);
    
    particle.collide();
    particle.move();
    particle.display();  
  }

  // Remove dead particles
  for (int i = particles.size() - 1; i >= 0; i-- ) {
    if( !((Particle) particles.get(i)).isAlive() ) {
      particles.remove(i);
    }
  }

  // Create new enemies
  if (enemies.size() < maxEnemies) {
    // If it's time to add a new enemy, look for one
    if (random(1) > .95 && enemyLoader.enemyAvailable()) {
      enemies.add(enemyLoader.getNextEnemy());
    }
  }

  for (int i = 0; i < enemies.size(); i++) {
    Enemy enemy = (Enemy) enemies.get(i);
    
    enemy.collide();
    enemy.move();
    enemy.display();  
  }
  
  // TODO: Remove dead enemies
  for (int i = enemies.size() - 1; i >= 0; i-- ) {
    if( !((Enemy) enemies.get(i)).isAlive() ) {
      enemies.remove(i);
    }
  }

  
  ship.draw();
}

class Starfield {
  Star[] stars = new Star[maxStars];
  
  Starfield() {
    for (int i = 0; i < maxStars; i++) {
      stars[i] = new Star(random(width), random(height),
                          int(random(3)),
                          starfield);
    }
  }
  
  void move() {
    for (int i = 0; i < maxStars; i++) {
      if (stars[i].isAlive()) {      
        stars[i].move();
      }
      else {
        // regenrate star
        if (random(1) > .9) {
          stars[i] = new Star(random(width), 0,
                          int(random(3)),
                          starfield);
        }
      }
    }
  }

  void display() {
    for (int i = 0; i < maxStars; i++) {
      stars[i].display();
    }
  }
}

class Star {
  float x, y;
  float v;
  int s;
  Starfield sparent;
  boolean alive;
 
  Star(float xin, float yin, int type, Starfield sparentin) {
    x = xin;
    y = yin;
    if (type == 0) {  
      v = 4;
      s = 4;
    }
    else if (type == 1) {  
      v = 3;
      s = 3;
    }
    else {  
      v = 2;
      s = 2;
    }
    sparent = sparentin;
    alive = true;
  } 
  
  void move() {
    if (alive) {
      y += v*scrollSpeed;      
    }
    
    if (y > height) {
      alive = false;
    }
  }
  
  boolean isAlive() {
    return alive;
  }

  void display() {
    if (alive) {
      fill(255, 204);
      rect(x, y, s, s);
    }
  }
}


class Enemy {
  int x, y;
  int w, h;
  
  float vx = 0;
  float vy = 0;
  float phase = 0;
  
  int id;
  ArrayList others;
  
  boolean loaded;    // All resources are loaded, enemy is ready to deploy
  boolean alive;     // Enemy is currently active
 
  PImage a;

  String title;
  String summary;
  String imageURL;
  
  Enemy(int xin, int yin, int idin, ArrayList oin) {
    x = xin;
    y = yin;
    
    w = 80;
    h = 60;
    
    id = idin;
    others = oin;
    alive = true;
    
    loaded = true;
  } 

  void setTitle(String title_) {
    title = title_;
  }
  
  void setSummary(String summary_) {
    summary = summary_;
  }
  
  void setImageURL(String imageURL_) {
    imageURL = imageURL_;
    
    // TODO: Set thing to load image asset
    // For now, just use the sample image
    if (imageURL == "") {
      // use a default
      a = loadImage("invader.png");  // Load the image into the program 
    }
    else {
      a = loadImage(imageURL);
    }
  }

  boolean isAlive() {
    return alive;
  }

  boolean isLoaded() {
    return loaded;
  }
  
  void collide() {
  }

  // enemy has been hit
  void hit() {
    // TODO: Add death animation
    enemyExplodeSound.trigger();
    PVector location = new PVector(x, y);
    
    // Draw up to 400 words from the summary text
    String summaryText[] = summary.split(" ");
    int textLength = min(summaryText.length, 400);
    for (int i = 0; i < textLength; i++) {
      particles.add(new textParticle(summaryText[i], location));
    }
      
    alive = false;
  }

  void move() {
    if (alive) {
      vy = scrollSpeed * 2;
//      vx = cos(phase) * 7;
      vx = 0;
    
      phase += .03;
      
      x += vx;
      y += vy;
    }
    
    if (y > height) {
      alive = false;
    }
  }

  void display() {
    if (alive) {
      if (a == null) {
        a = loadImage("invader.png");  // Load the image into the program 
      }

      image(a, x, y, w, h);
    }
  }
}


class Particle {
  boolean alive;
  
  // animation phase
  float phase = 0;
  
  Particle() {
    alive = true;
  }
  
  boolean isAlive() {
    return alive;
  }
  
  void collide() {
    // Do you collide with anything?
  }

  void move() {
    // Compute movements here
  }

  void display() {
    // Show thyself!
  }  
}

class textParticle extends Particle {
  PVector loc;
  PVector vel;
  PVector acc;
  float timer;
  String s;
  
  PFont font;
  
  textParticle(String _s, PVector l) {
    s = _s;
    acc = new PVector(0,0.12,0);
    vel = new PVector(random(-2.5,2.5),random(-6,-2),0);
    loc = l.get();
    timer = 150.0;
  }

  textParticle(String _s, PVector l, PFont font_, PVector acc_, PVector vel_, float timer_) {
    font = font_;
    s = _s;
    acc = acc_;
    vel = vel_;
    loc = l.get();
    timer = timer_;
  }


  // Method to update location
  void move() {
    vel.add(acc);
    loc.add(vel);
    timer -= 1.0;
  }

  // Method to display
  void display() {
    ellipseMode(CENTER);
    stroke(255,timer);
    fill(255,timer);
    
    if (font != null) {
      textFont(font);
    }
    
    text(s, loc.x, loc.y); 
    
    if (font != null) {
      // TODO: Context save/restore?
      textFont(fountainFont);
    }
  }
  
  boolean isAlive() {
    if (timer <= 0.0) {
      return false;
    } else {
      return true;
    }
  }
}


class phaserParticle extends Particle {
  int x = 0;
  int y = 0;
  
  float vx = 0;
  float vy = 0;

  
  phaserParticle(int xin, int yin, float vxin, float vyin) {
    x = xin;
    y = yin;
    vx = vxin;
    vy = vyin;
  }
  
  
  void collide() {
    if (alive) {
      // Particles only collide with enemies
      // Particles are considered point sources!
      
      for (int i = 0; i < enemies.size(); i++) {
        Enemy enemy = (Enemy) enemies.get(i);
        if (enemy.isAlive()) {
//          if( (x - enemy.x <= enemy.w) && (y - enemy.y <= enemy.h)) {
          if( (x >= enemy.x) && (x <= enemy.x + enemy.w) && (y >= enemy.y) && (y <= enemy.y + enemy.h)) {
            enemy.hit();
                alive = false;
                break;
          }
        }
      }
    }
  }

  
  void move() {
    if (alive) {
      x += vx;
      y += vy;
    
      // TODO: Adjust for size of particle
      if (x < 0 || x > width || y < 0 || y > height) {
        alive = false;
      }
    }
    
    phase += .5;
  }
  
  void display() {
    if (alive) {
      fill(255,0,0,190);
      ellipse(x, y, 15+2*cos(phase), 15+2*cos(phase));
      fill(220,0,0,10);
      ellipse(x, y, 15+4*cos(phase), 15+4*cos(phase));
    }
  }    
}


class PlayerShip {
  int w = 64;
  int h = 64;

  int y_max = h * 3;

  int x = 0;
  int y = 0;
  
  int dx = 0; // -1, 0, 1
  int dy = 0; // -1, 0, 1
  int v = w / 12;
  
  int hWheel = 0;  // Hue wheel
  
  PlayerShip(){
     x = (width - w) / 2;
     y = ((y_max - h) / 2) + (height - y_max);
  }
  
  void draw() {
    // First, make sure ship is still on-screen
    x = (int)((float) x + dx * v);
    if(x > (width - w)) { x = (width - w); }
    if(x < 0) { x = 0; }
    y = (int)((float)y + dy * v);
    if(y > (height - h)) { y = (height - h); }
    if(y < (height - y_max)) { y = (height - y_max); }

    // then, draw!
    colorMode(HSB, 255);
    color c = color(hWheel, 126, 255);
    fill(c);
 
    beginShape();
    vertex(x, y+h);
    vertex(x+w, y+h);
    vertex(x+w/2, y);
    endShape(CLOSE);
    
    // reset to RGB draw mode
    colorMode(RGB, 255);
    
    // Increment the color wheel
    hWheel = (hWheel + 1) % 255;
    
//    fill(255);
//    rect(x,y,w,h);
  }
  
}

boolean[] playerMotion = new boolean[4];

void keyPressed(){
  if(key == CODED){
    if(keyCode == LEFT){
      ship.dx = -1;
      playerMotion[0] = true;
    } else if(keyCode == RIGHT){
      ship.dx = 1;      
      playerMotion[1] = true;
    } else if(keyCode == UP) {
      ship.dy = -1;
      playerMotion[2] = true;
    } else if(keyCode == DOWN) {
      ship.dy = 1;
      playerMotion[3] = true;
    }
  }
}

void keyReleased(){
  if(key == CODED){
    if(keyCode == LEFT) {
      playerMotion[0] = false;
      if(playerMotion[1] == true) {
        ship.dx = 1;
      }
      else {
        ship.dx = 0;
      }
    }
    else if(keyCode == RIGHT) {
      playerMotion[1] = false;
      if(playerMotion[0] == true) {
        ship.dx = -1;
      }
      else {
        ship.dx = 0;
      }
    }
    else if(keyCode == UP) {
      playerMotion[2] = false;
      if(playerMotion[3] == true) {
        ship.dy = 1;
      }
      else {
        ship.dy = 0;
      }
    }
    else if(keyCode == DOWN) {
      playerMotion[3] = false;
      if(playerMotion[2] == true) {
        ship.dy = -1;
      }
      else {
        ship.dy = 0;
      }
    } 
  }
  else if (key == ' ') {
    // Fire!  She screamed!
    // TODO: Compute center of ship correctly
    zapSound.trigger();
    particles.add(new phaserParticle(ship.x + 32, ship.y, 0 , -14));
  }
}
