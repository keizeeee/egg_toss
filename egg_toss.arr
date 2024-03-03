use context essentials2021
import reactors as R
import image as I

### TYPES ###

data PlatformLevel:
  |top
  |middle
  |bottom
end

data GameStatus:
  |ongoing
  |transitioning
  |game-over
end

type Platform = {
  x :: Number,
  y :: Number,
  dx :: Number,
}

type Egg = {
  x :: Number,
  y :: Number,
  dx :: Number,
  dy :: Number,
  ay :: Number,
  is-airborne :: Boolean,
}

type State = {
  game-status :: GameStatus,
  egg :: Egg,
  top-platform :: Platform,
  middle-platform :: Platform,
  bottom-platform :: Platform,
  current-platform :: PlatformLevel,
  other-platforms :: List<Platform>,
  score :: Number,
  lives :: Number,
  timer :: Number,

}

### CONSTANTS ###

FPS = 60

SCREEN-WIDTH = 300
HALF-SCREEN-WIDTH = SCREEN-WIDTH / 2
SCREEN-HEIGHT = 500
HALF-SCREEN-HEIGHT = SCREEN-HEIGHT / 2

EGG-RADIUS = 13
EGG-COLOR = "navajo white"
EGG-JUMP-HEIGHT = -14
EGG-JUMP-ACCE = 0.5

PLATFORM-HEIGHT = 12
HALF-PLATFORM-HEIGHT = PLATFORM-HEIGHT / 2
PLATFORM-WIDTH = SCREEN-WIDTH * (1 / 5)
HALF-PLATFORM-WIDTH = PLATFORM-WIDTH / 2
PLATFORM-COLOR = "saddle-brown"

DIST-BETWEEN-PLATFORMS = 125
TRANSITION-TIME = 2 * FPS #ticks
PANNING-SPEED = (DIST-BETWEEN-PLATFORMS / TRANSITION-TIME) * 2

top-plat = {
  x: num-random(SCREEN-WIDTH - PLATFORM-WIDTH) + HALF-PLATFORM-WIDTH, #random platform starting point
  y: 145,
  dx: num-random(4) + 1,
}


mid-plat = {
  x: num-random(SCREEN-WIDTH - PLATFORM-WIDTH) + HALF-PLATFORM-WIDTH,
  y: 270,
  dx: num-random(4) + 1,
}

bot-plat = {
  x: num-random(SCREEN-WIDTH - PLATFORM-WIDTH) + HALF-PLATFORM-WIDTH,
  y: 395,
  dx: num-random(4) + 1,
}

INITIAL-EGG = {
  x: bot-plat.x,
  y: bot-plat.y - (PLATFORM-HEIGHT / 2) - EGG-RADIUS,
  dx: 0,
  dy: 0,
  ay: 0,
  is-airborne: false,
}

INITIAL-STATE = {
  game-status: ongoing,
  egg: INITIAL-EGG,
  top-platform: top-plat,
  middle-platform: mid-plat,
  bottom-platform: bot-plat,
  current-platform: bottom,
  other-platforms: [list: ],
  score: 0,
  lives: 12,
  timer: 0,
}

### HELPER FUNCTIONS ###

fun get-platform(state :: State, plat-level :: PlatformLevel):
  cases (PlatformLevel) plat-level:
    |top => state.top-platform
    |middle => state.middle-platform
    |bottom => state.bottom-platform
  end
end

fun is-egg-on-platform(state :: State) -> Boolean:
  curr-plat = get-platform(state, state.current-platform)

  egg-center-within-platform = range(curr-plat.x - (HALF-PLATFORM-WIDTH), curr-plat.x + (HALF-PLATFORM-WIDTH) + 1).member(state.egg.x)

  egg-collision-with-plat-top = (curr-plat.y - (HALF-PLATFORM-HEIGHT)) <= (state.egg.y + EGG-RADIUS)
  egg-collision-with-plat-bot = (state.egg.y + EGG-RADIUS) <= (curr-plat.y + (HALF-PLATFORM-HEIGHT))

  egg-center-within-platform and egg-collision-with-plat-top and egg-collision-with-plat-bot
end

### DRAWING ###

fun draw-egg(state :: State, img :: Image) -> Image:
  egg = circle(EGG-RADIUS, "solid", EGG-COLOR)
  I.place-image(egg, state.egg.x, state.egg.y, img)
end

fun draw-platform(platform :: Platform, img :: Image) -> Image:
  platform-img = rectangle(PLATFORM-WIDTH, PLATFORM-HEIGHT, 'solid', PLATFORM-COLOR)
  I.place-image(platform-img, platform.x, platform.y, img)
end

fun draw-platforms(state :: State, img :: Image) -> Image:
  fun helper(lst :: List<Platform>, acc :: Image):
    cases (List) lst:
      |empty => acc
      |link(first, rest) => helper(rest, draw-platform(first, acc))
    end
  end
  three-platforms = [list: state.top-platform, state.middle-platform, state.bottom-platform].append(state.other-platforms)
  helper(three-platforms, img)
end

fun draw-lives(state :: State, img :: Image) -> Image:
  lives-img = text("Lives: " + num-to-string(state.lives), 15, "black")
  I.place-image(lives-img, SCREEN-WIDTH * (6 / 7), SCREEN-HEIGHT * (1 / 25), img)
end

fun draw-score(state :: State, img :: Image) -> Image:
  score-img = text(num-to-string(state.score), 27, "black")
  I.place-image(score-img, SCREEN-WIDTH * (1 / 2), SCREEN-HEIGHT * (1 / 10), img)
end

fun draw-game-over(state :: State, img :: Image) -> Image:
  cases (GameStatus) state.game-status:
    | ongoing => img
    | transitioning => img
    | game-over =>
      text-img = text("GAME OVER", 48, "red")
      I.place-image(text-img, SCREEN-WIDTH / 2, SCREEN-HEIGHT / 2, img)
  end
end

fun draw-handler(state :: State) -> Image:
  canvas = empty-color-scene(SCREEN-WIDTH, SCREEN-HEIGHT, "light-blue")
  cases (GameStatus) state.game-status:
    |ongoing =>
      canvas
        ^ draw-platforms(state, _)
        ^ draw-egg(state, _)
        ^ draw-lives(state, _)
        ^ draw-score(state, _)
    |transitioning =>
      canvas
        ^ draw-platforms(state, _)
        ^ draw-egg(state, _)
        ^ draw-lives(state, _)
        ^ draw-score(state, _)

    |game-over =>
      canvas
        ^ draw-platforms(state, _)
        ^ draw-egg(state, _)
        ^ draw-lives(state, _)
        ^ draw-score(state, _)
        ^ draw-game-over(state, _)
  end
end

### KEYBOARD ###

fun key-handler(state :: State, key :: String) -> State:
  cases (GameStatus) state.game-status:
    |ongoing =>
      
  if (key == ' ') and is-egg-on-platform(state):
    make-airborne = state.egg.{dx: 0, dy: EGG-JUMP-HEIGHT, ay: EGG-JUMP-ACCE, is-airborne: true}
    state.{egg: make-airborne}

  else:
    state
  end
    |transitioning => state
    |game-over => INITIAL-STATE
  end
end


### TICKS ###

fun update-x-velocity(state :: State) -> State:
  curr-plat-velocity = 
    cases (PlatformLevel) state.current-platform:
      |top => state.top-platform.dx
      |middle => state.middle-platform.dx
      |bottom => state.bottom-platform.dx
    end
  new-egg = state.egg.{dx: curr-plat-velocity, x: state.egg.x + state.egg.dx}
  state.{egg: new-egg}
end

fun update-y-velocity(state :: State) -> State:
  new-egg = state.egg.{dy: state.egg.dy + state.egg.ay}
  state.{egg: new-egg}
end

fun update-y-coordinate(state :: State) -> State:
  new-egg = state.egg.{y: state.egg.y + state.egg.dy}
  state.{egg: new-egg}
end

fun update-platform(platform :: Platform) -> Platform:
  platform.{x: platform.x + platform.dx}
end

fun update-platforms(state :: State) -> State:
  new-bottom-platform = update-platform(state.bottom-platform)
  new-middle-platform = update-platform(state.middle-platform)
  new-top-platform = update-platform(state.top-platform)
  other-plat = state.other-platforms.map(update-platform)

  state.{bottom-platform: new-bottom-platform, middle-platform: new-middle-platform, top-platform: new-top-platform}.{other-platforms: other-plat}
end

fun update-collision(platform :: Platform) -> Platform:

  plat-right = platform.x + (HALF-PLATFORM-WIDTH)
  plat-left = platform.x - (HALF-PLATFORM-WIDTH)


  is-hitting-right-wall = plat-right >= SCREEN-WIDTH
  is-hitting-left-wall = plat-left <= 0

  if is-hitting-right-wall or is-hitting-left-wall: 
    platform.{dx: platform.dx * -1}
  else:
    platform
  end

end

fun update-collisions(state :: State) -> State:
  bottom-collision = update-collision(state.bottom-platform)
  middle-collision = update-collision(state.middle-platform)
  top-collision = update-collision(state.top-platform)
  other-plat = state.other-platforms.map(update-collision)

  state.{bottom-platform: bottom-collision, middle-platform: middle-collision, top-platform: top-collision}.{other-platforms: other-plat}
end

fun update-egg-on-platform(state :: State) -> State:

  curr-platform = get-platform(state, state.current-platform)
  next-platform = 
    cases (PlatformLevel) state.current-platform:
      |top => state.middle-platform
      |middle => state.top-platform
      |bottom => state.middle-platform
    end

  is-airborne = state.egg.is-airborne
  egg-is-falling = state.egg.dy > 0
  egg-center-within-platform = range(next-platform.x - (HALF-PLATFORM-WIDTH), next-platform.x + (PLATFORM-WIDTH / 2) + 1).member(state.egg.x)

  egg-collision-with-plat-top = (next-platform.y - (HALF-PLATFORM-HEIGHT)) <= (state.egg.y + EGG-RADIUS)
  egg-collision-with-plat-bot = (state.egg.y + EGG-RADIUS) <= (next-platform.y + (HALF-PLATFORM-HEIGHT))
  egg-bottom-collision-with-plat = egg-collision-with-plat-top and egg-collision-with-plat-bot

  new-curr-plat =
    cases (PlatformLevel) state.current-platform:
      |top => middle
      |middle => top
      |bottom => middle
    end

  egg-land-on-plat = is-airborne and egg-is-falling and egg-center-within-platform and egg-bottom-collision-with-plat


  if egg-land-on-plat:
    new-egg = state.egg.{x: state.egg.x, y: (next-platform.y - (HALF-PLATFORM-HEIGHT)) - EGG-RADIUS, dx: next-platform.dx, dy: 0, ay: 0}           
    new-state = state.{egg: new-egg}.{is-airborne: false}.{current-platform: new-curr-plat}.{score: state.score + 1}
    if new-state.current-platform == top:
      new-state.{game-status: transitioning}
    else:
      new-state
    end
  else:
    state
  end

end 

fun update-lives(state :: State) -> State:
  egg-bottom = state.egg.y + EGG-RADIUS
  curr-plat = get-platform(state, state.current-platform)
  is-hitting-bottom-wall = egg-bottom >= SCREEN-HEIGHT
  if is-hitting-bottom-wall:
    new-egg = state.egg.{x: curr-plat.x, y: curr-plat.y - (HALF-PLATFORM-HEIGHT) - EGG-RADIUS, dy: 0, ay: 0, is-airborne: false}
    state.{egg: new-egg}.{lives: state.lives - 1}
  else:
    state
  end
end

fun update-gameover(state :: State) -> State:
  if state.lives <= 0:
    state.{game-status: game-over}
  else:
    state
  end
end

fun generate-platforms(state :: State) -> State:
  new-timer = state.timer + 1
  if state.timer < 1:
    new-middle = {x: num-random(SCREEN-WIDTH - PLATFORM-WIDTH) + HALF-PLATFORM-WIDTH , y: state.top-platform.y - 125,dx: mid-plat.dx}
    new-top = {x: num-random(SCREEN-WIDTH - PLATFORM-WIDTH) + HALF-PLATFORM-WIDTH, y: new-middle.y - 125, dx: top-plat.dx}
    new-platforms = state.other-platforms.append([list: new-middle,  new-top])
    state.{other-platforms: new-platforms}.{timer: 0}
  else:
    state
  end
end

fun pan-platform-egg(state :: State) -> State:
  if (state.current-platform == top) and (state.timer < TRANSITION-TIME):
    new-timer = state.timer + 1
    a = state.bottom-platform.{y: state.bottom-platform.y + PANNING-SPEED, dx: 0} 
    b = state.middle-platform.{y: state.middle-platform.y + PANNING-SPEED, dx: 0}
    c = state.top-platform.{y: state.top-platform.y + PANNING-SPEED, dx: 0}
    d = state.egg.{dx: 0, y: state.egg.y + PANNING-SPEED}
    other-plat = state.other-platforms.map(lam(plat): plat.{y: plat.y + PANNING-SPEED} end)
    state.{egg: d}.{bottom-platform: a, middle-platform: b, top-platform: c}.{other-platforms: other-plat}.{timer: new-timer}
  else:
    new-top-plat = top-plat.{x: state.top-platform.x, y: state.top-platform.y}
    state.{game-status: ongoing}.{bottom-platform: new-top-plat}.{middle-platform: state.other-platforms.get(0)}.{top-platform: state.other-platforms.get(1)}.{current-platform: bottom}.{timer: 0}.{other-platforms: [list: ]}
  end
end

fun tick-handler(state :: State) -> State:
  cases (GameStatus) state.game-status:
    |ongoing => 
      state
        ^ update-y-velocity(_)
        ^ update-y-coordinate(_)
        ^ update-x-velocity(_)
        ^ update-platforms(_)
        ^ update-collisions(_)
        ^ update-egg-on-platform(_)
        ^ update-lives(_)
        ^ update-gameover(_)
    |transitioning =>
      state
        ^ generate-platforms(_)
        ^ pan-platform-egg(_)
    |game-over => state
  end
end


### MAIN ###

world = reactor:
  title: "Simple Egg Toss",
  init: INITIAL-STATE,
  to-draw: draw-handler,
  seconds-per-tick: 1 / FPS,
  on-tick: tick-handler,
  on-key: key-handler,

end

R.interact(world)