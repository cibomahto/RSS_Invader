int maxEnemies = 20;
int maxStars = 50;

float scrollSpeed = 1;

Starfield starfield;

Enemy[] enemies = new Enemy[maxEnemies];

void setup()
{
  size(800,600);
  frameRate(30);
  
  starfield = new Starfield();
  
  noStroke();
  smooth();
  for (int i = 0; i < maxEnemies; i++) {
    enemies[i] = new Enemy(random(width), random(height), i, enemies);
  }
}

void draw()
{
  background(0);
  
  starfield.move();
  starfield.display();

  for (int i = 0; i < maxEnemies; i++) {
    enemies[i].collide();
    enemies[i].move();
    enemies[i].display();  
  }
}

class Enemy {
  float x, y;
  float vx = 0;
  float vy = 0;
  int id;
  Enemy[] others;
 
  Enemy(float xin, float yin, int idin, Enemy[] oin) {
    x = xin;
    y = yin;
    id = idin;
    others = oin;
  } 
  
  void collide() {
  }
/*
  void collide() {
    for (int i = id + 1; i < numBalls; i++) {
      float dx = others[i].x - x;
      float dy = others[i].y - y;
      float distance = sqrt(dx*dx + dy*dy);
      float minDist = others[i].diameter/2 + diameter/2;
      if (distance < minDist) { 
        float angle = atan2(dy, dx);
        float targetX = x + cos(angle) * minDist;
        float targetY = y + sin(angle) * minDist;
        float ax = (targetX - others[i].x) * spring;
        float ay = (targetY - others[i].y) * spring;
        vx -= ax;
        vy -= ay;
        others[i].vx += ax;
        others[i].vy += ay;
      }
    }   
  }
*/

/*
  void move() {
    vy += gravity;
    x += vx;
    y += vy;
    if (x + diameter/2 > width) {
      x = width - diameter/2;
      vx *= friction; 
    }
    else if (x - diameter/2 < 0) {
      x = diameter/2;
      vx *= friction;
    }
    if (y + diameter/2 > height) {
      y = height - diameter/2;
      vy *= friction; 
    } 
    else if (y - diameter/2 < 0) {
      y = diameter/2;
      vy *= friction;
    }
  }
*/
  void move() {
    vy = 15;
    
    x += vx;
    y += vy;
  }

  void display() {
    fill(255, 204);
    ellipse(x, y, 30, 30);
  }
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
