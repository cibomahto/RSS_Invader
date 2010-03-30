import com.creatingwithcode.greader.GoogleReaderClient;
import com.creatingwithcode.greader.RecentItemsFeed;
import com.creatingwithcode.greader.FeedItem;

import ddf.minim.*;

AudioPlayer player;
Minim minim;
PlayerShip ship;

int maxEnemies = 20;
int maxStars = 50;

float scrollSpeed = 1;

Starfield starfield;

ArrayList enemies;
ArrayList particles;

// Create the object with the run() method
EnemyLoader enemyLoader;
Thread loadThread;


class EnemyLoader implements Runnable {
  ArrayList working;    // RSS items that are still loading (image, etc)
  ArrayList ready;      // RSS items that are ready to go

  GoogleReaderClient grc;
  
  // This method is called when the thread runs
  public void run() {
    // Google reader client bits
    
    // Replace this with you username/password
//    grc = new GoogleReaderClient("username", "password");


    RecentItemsFeed rif;
    rif = grc.getRecentItemsFeed();
  
    Iterator rifi = rif.getItems().iterator();
    while(rifi.hasNext()){
      FeedItem fi = (FeedItem) rifi.next();

      println(fi.getTitle());
      
      // Build a new enemy, and stuff it with our info
//      Enemy newEnemy = new Enemy(int(random(width)), -30, fi.getId(), enemies);
      Enemy newEnemy = new Enemy(int(random(width)), -30, 0, enemies);

      newEnemy.setTitle(fi.getTitle());

      if ( fi.getSummary() != null 
           && fi.getSummary().containsKey("content") ) {
             
        println(fi.getSummary().get("content"));
        newEnemy.setSummary(fi.getSummary().get("content"));
      }
      else {
        println("  no content");
      }
      
//      newEnemy.addTitle(fi.getTitle());
      
      working.add(newEnemy);
    }

    while(true) {
      try{ 
        Thread.sleep(10);
      } catch( InterruptedException e ) {
        println("Interrupted Exception caught");
      }
    }
  }
  
//  Enemy getNewEnemy() {
//    if (ready.size() > 0)
//  }
}


void setup()
{
  // Video bits
  size(800,600);
  frameRate(30);
  noStroke();
  smooth();

  // Audio bits

  minim = new Minim(this);
  
  // load a file, give the AudioPlayer buffers that are 2048 samples long
  player = minim.loadFile("song.mp3", 2048);
  // play the file
//  player.play();

  enemyLoader = new EnemyLoader();
  loadThread=new Thread(enemyLoader);

  loadThread.start();
  
  // Game bits
  starfield = new Starfield();
  enemies = new ArrayList();
  particles = new ArrayList();
  ship = new PlayerShip();

//  for (int i = 0; i < maxEnemies; i++) {
//    enemies.add(new Enemy());
//    enemies[i] = new Enemy();
//  }
}

void draw()
{
  background(0);
  
  starfield.move();
  starfield.display();

  // Create new enemies
  if (enemies.size() < maxEnemies) {
    if (random(1) > .95) {
      enemies.add(new Enemy(int(random(width)), -30, 0, enemies));
//      enemy = new Enemy(random(width), -30, i, enemies);
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
    if( !((Enemy) enemies.get(i)).isalive() ) {
      enemies.remove(i);
    }
  }

  // do the particles
  for (int i = 0; i < particles.size(); i++) {
    Particle particle = (Particle) particles.get(i);
    
    particle.collide();
    particle.move();
    particle.display();  
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
      if (stars[i].isalive()) {      
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
  
  boolean isalive() {
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
  boolean alive;
 
  PImage a;

  String title;
  String summary;
  String imageURL;
  
  Enemy(int xin, int yin, int idin, ArrayList oin) {
    x = xin;
    y = yin;
    
    w = 50;
    h = 40;
    
    id = idin;
    others = oin;
    alive = true;
  } 

  void setTitle(String title_) {
    title = title_;
  }
  
  void setSummary(String summary_) {
    summary = summary_;
  }
  
  void setImageURL(String imageURL_) {
    imageURL = imageURL;
    
    // TODO: Set thing to load image asset
    // For now, just use the sample image
    a = loadImage("cathedral.jpg");  // Load the image into the program 
  }

  boolean isalive() {
    return alive;
  }
  
  void collide() {
  }

  // enemy has been hit
  void hit() {
    // TODO: Add death animation
    alive = false;
  }

  void move() {
    if (alive) {
      vy = scrollSpeed * 1.5;
      vx = cos(phase) * 7;
    
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
      image(a, x, y, w, h);
    }
  }
}


class Particle {
  int x = 0;
  int y = 0;
  
  float vx = 0;
  float vy = 0;
  
  boolean alive;
  
  // animation phase
  float phase = 0;
  
  Particle(int xin, int yin, float vxin, float vyin, ArrayList oin) {
    x = xin;
    y = yin;
    vx = vxin;
    vy = vyin;
    alive = true;
  }
  
  void collide() {
    if (alive) {
      // Particles only collide with enemies
      for (int i = 0; i < enemies.size(); i++) {
        Enemy enemy = (Enemy) enemies.get(i);
        if (enemy.isalive()) {
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
  
  PlayerShip(){
     x = (width - w) / 2;
     y = ((y_max - h) / 2) + (height - y_max);
  }
  
  void draw() {
    x = (int)((float) x + dx * v);
    if(x > (width - w)) { x = (width - w); }
    if(x < 0) { x = 0; }
    y = (int)((float)y + dy * v);
    if(y > (height - h)) { y = (height - h); }
    if(y < (height - y_max)) { y = (height - y_max); }
    fill(255);
    rect(x,y,w,h);
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
    particles.add(new Particle(ship.x + 25, ship.y, 0, -14, particles));
  }
}
