final int logLen = 40;
final int logHeight = 7;

PVector starter;

final int FIRE_R = 6;
final float FIRE_RATE = 0.5;
final float FIRE_AC_LOWER = -5;
final float FIRE_AC_UPPER = -1;
final color FIRE_START = color(255, 127, 0);
final color FIRE_END = color(127, 0, 0);
float FIRE_HEIGHT;
ArrayList<Fire> fire = new ArrayList<Fire>();

final int SMOKE_R = 4;
final float SMOKE_RATE = 0.2;
final float SMOKE_AC_LOWER = -10;
final float SMOKE_AC_UPPER = -2.5;
ArrayList<Smoke> smoke = new ArrayList<Smoke>();

ArrayList<Wind> wind = new ArrayList<Wind>();

void setup() {
  size(600, 400);
  
  starter = new PVector(width / 2, height - 20);
  
  FIRE_HEIGHT = height * 0.3;
  
  //for (int i = 0; i < 200; i++) {
  //  wind.add(new Wind());
  //}
  
  addNewWind();
  addNewWind();
}

void draw() {
  background(0);  
  
  //logs
  noStroke();
  fill(139,69,19);
  rectMode(CENTER);

  pushMatrix();
  translate(starter.x, starter.y);
  rotate(PI / 6);
  rect(0, 0, logLen, logHeight);
  popMatrix();
  
  pushMatrix();
  translate(starter.x, starter.y);
  rotate(-PI / 6);
  rect(0, 0, logLen, logHeight);
  popMatrix();
  
  
  //Possible idea:
  //use beginShpae/endShape with gift wrapping algorithm
  for (int i = smoke.size() - 1; i >= 0; i--) {
    Smoke s = smoke.get(i);
    s.update();
      s.show();
    
    if (s.alpha < 0 || s.pos.y < 0) {
      smoke.remove(i);
    }
  }
  
  
  //Fire
  if (random(1) < FIRE_RATE) {
    fire.add(new Fire());
  }
  
  for (int i = fire.size() - 1; i >= 0; i--) {
    Fire f = fire.get(i);
    f.updateF();
      f.show();
    
    if (f.alpha < 0 || f.pos.y < 0) {
      fire.remove(i);
    }
    
    
    //create more smoke
    //if (f.pos.y > height - FIRE_HEIGHT && random(1) < SMOKE_RATE) {
     if (random(1) < SMOKE_RATE * (f.pos.y / height)) {
      for (int j = 0; j < 1; j++) {
        smoke.add(new Smoke(f.pos.x, f.pos.y));
      }
    }
  }
  
  //Wind
  for (int i = wind.size() - 1; i >= 0; i--) {
    Wind w = wind.get(i);
    w.update();
    
    if (w.pos.x > width) {
      wind.remove(i);
      //wind.add(new Wind());
    }
  }
  
  if (wind.size() < 25) {
    addNewWind();
    addNewWind();
  }
}

void addNewWind() {
  int numWinds = floor(random(50, 100));
  PVector sourcePos = new PVector(random(width), random(50, height - 50));
  for (int i = 0; i < numWinds; i++) {
    PVector offset = PVector.random2D().mult(random(25, 75));
    PVector newPos = PVector.add(sourcePos, offset);
    wind.add(new Wind(newPos.x, newPos.y));
  }
}

class Particle {
  PVector pos;
  PVector dir;
  float noiseX;
  float noiseY;
  int r;
  float alpha;
  float alphaChange;
  color col;
    
  Particle(float x, float y, float aC, int r_, color c) {
    pos = new PVector(x, y);
    float dirX = random(1, 2) * ((random(1) > 0.5 ? 1 : -1)); //get random number -2 to -1 or 1 to 2 (either way |dirX| > 1 so it scales)
    dir = new PVector(dirX, random(-5, -1));
    noiseX = random(10);
    noiseY = random(10);
    alpha = 255;
    alphaChange = aC;
    r = r_;
    col = c;
  }
  
  void show() {
    fill(col, alpha);
    noStroke();
    ellipse(pos.x, pos.y, r * 2, r * 2);
  }
  
  void update() {
    PVector vel = new PVector(noise(noiseX), noise(noiseY));
    vel.x *= dir.x * map(pos.y, height, 0, 1, 0);
    vel.y *= dir.y;
    PVector windForce = checkWind(this);
    //println(windForce);
    vel.add(windForce);
    pos.x += vel.x;
    pos.y += vel.y;
    noiseX += 0.01;
    noiseY += 0.01;
    alpha += alphaChange;
  }
}

class Smoke extends Particle {
  Smoke(float x, float y) {
    super(
      x,
      y,
      random(SMOKE_AC_LOWER, SMOKE_AC_UPPER),
      SMOKE_R,
      color(150)
    );
  }
}

class Fire extends Particle {
  float xBuffer = random(-10, 10);
  
  Fire() {
    super(
      starter.x,
      starter.y,
      random(FIRE_AC_LOWER, FIRE_AC_UPPER),
      FIRE_R,
      FIRE_START
    );
  }
  
  void updateF() {
    update();
    
    float pxMax = map(pos.y, height - 10, FIRE_HEIGHT, 0, 100);
    pxMax += xBuffer;
    //pos.x = constrain(pos.x, width / 2 - pxMax, width / 2 + pxMax);      from before adding wind
    pos.x = max(pos.x, width / 2 - pxMax); //                              would have to change for wind of a different direction  
    pos.y = min(pos.y, height - 10);
    
    //100 x FIRE_HEIGHT triangle
    final float hypotenuseMax = sqrt(10000 + pow(FIRE_HEIGHT, 2));
    final float amt = map(PVector.dist(pos, starter), 0, hypotenuseMax, 0, 1);
    col = lerpColor(FIRE_START, FIRE_END, amt);
    //col = lerpColor(FIRE_END, FIRE_START, pos.y / height);
  }
}


class Wind {
  //PVector pos = new PVector(random(width), random(height));
  PVector pos;
  //PVector vel = new PVector(random(5), 0);
  //PVector vel = new PVector(random(5) + map(pos.y, height, 0, 0, 5), 0);
  //PVector vel = new PVector(2 * pow(1.75,(height - pos.y) / 100), 0);
  PVector vel;
  
  Wind(float x, float y) {
    pos = new PVector(x, y);
    vel = new PVector(random(2.5) + map(pos.y, height, 0, 0, 5), 0);
  }
  
  void update() {
    //fill(0, 0, 255);
    //ellipse(pos.x, pos.y, vel.mag() * 2, vel.mag() * 2);
    
    pos.add(vel);
  }
}

PVector checkWind(Particle p) {
  PVector push = new PVector(0, 0);
  for (int i = 0; i < wind.size(); i++) {
    Wind w = wind.get(i);
    if (w.pos.x <= p.pos.x) {        //just to cut down on the calculations, definitely could optimize better
      if (PVector.dist(p.pos, w.pos) < p.r + w.vel.mag()) {
        push.add(w.vel);
      }
    }
  }
  return push;
}
