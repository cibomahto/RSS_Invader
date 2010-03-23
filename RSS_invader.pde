import ddf.minim.*;

AudioPlayer player;
Minim minim;


int maxEnemies = 20;
int maxStars = 50;

float scrollSpeed = 1;

Starfield starfield;

//Enemy[] enemies = new Enemy[maxEnemies];
ArrayList enemies = new ArrayList();

void setup()
{
  size(800,600);
  frameRate(30);
  
  starfield = new Starfield();

  minim = new Minim(this);
  
  // load a file, give the AudioPlayer buffers that are 2048 samples long
  player = minim.loadFile("song.mp3", 2048);
  // play the file
//  player.play();
  
  noStroke();
  smooth();
//  for (int i = 0; i < maxEnemies; i++) {
//    enemies.add(new Enemy());
 //   enemies[i] = new Enemy();
  }
}

void draw()
{
  background(0);
  
  starfield.move();
  starfield.display();

  if (enemies.size() < maxEnemies) {
    if (random(1) > .995) {
      enemy = new Enemy(random(width), -30, i, enemies);
    }
  }


  for (int i = 0; i < enemies.size(); i++) {
    Enemy enemy = (Enemy) enemy.get(i);
    
    enemy.collide();
    enemy.move();
    enemy.display();  
  }  
  
  // Remove dead enemies
  
}

class Starfield {
  Star[] stars = new Star[maxStars];
  
  Starfield() {
    for (int i = 0; i < maxStars; i++) {
      stars[i] = new Star(random(width), random(height),
                          int(random(2)),
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
                          int(random(2)),
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
  Boolean alive;
 
  Star(float xin, float yin, int type, Starfield sparentin) {
    x = xin;
    y = yin;
    if (type == 0) {  
      v = 4;
      s = 4;
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
  
  Boolean isalive() {
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
  float x, y;
  float vx = 0;
  float vy = 0;
  float phase = 0;
  
  int id;
  Enemy[] others;
  Boolean alive;
 
  PImage a;
   
  Enemy(float xin, float yin, int idin, Enemy[] oin) {
    x = xin;
    y = yin;
    id = idin;
    others = oin;
    alive = true;
    
    // For now, just use the sample image
    a = loadImage("cathedral.jpg");  // Load the image into the program  
  } 

  Boolean isalive() {
    return alive;
  }
  
  void collide() {
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
      image(a, x, y, 50, 40);
//      fill(255, 204);
//      ellipse(x, y, 30, 30);
    }
  }
}
