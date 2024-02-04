import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;

import derelict.opengl;
mixin glFreeFuncs!(GLVersion.gl45);



struct Game 
{
	SDL_Window* window;
	SDL_Renderer* renderer;
	SDL_GLContext glContext;
	bool queueGracefulExit = false;
}
Game globalGame;

class Primitive 
{
	float[] verts = [];
}

class Rectangle : Primitive
{

}

class Circle : Primitive
{

}

class Diamond : Primitive
{

}

class Renderable
{
	Primitive primitive;
	uint vertexArrayObject;
}

class Sprite : Renderable
{
	SDL_Surface *img;
	
	this(Primitive _prim) {
		this.primitive = _prim;
	}
}

void initSDL() {
	if(SDL_Init(SDL_INIT_EVERYTHING) < 0) {
		stderr.writefln("SDL Failed to Init: %s", SDL_GetError());
		return;
	}

	SDL_WindowFlags windowFlags = SDL_WINDOW_OPENGL | SDL_WINDOW_INPUT_GRABBED | SDL_WINDOW_BORDERLESS;
	globalGame.window = SDL_CreateWindow("Hello", SDL_WINDOWPOS_CENTERED, SDL_WINDOWPOS_CENTERED, 1280, 720, windowFlags);

	if(!globalGame.window) {
		stderr.writefln("SDL Window failed to create: %s", SDL_GetError());
		return;
	}

	// globalGame.renderer = SDL_CreateRenderer(globalGame.window, -1, SDL_RENDERER_ACCELERATED);

	// if(!globalGame.renderer) {
	// 	stderr.writefln("SDL Renderer failed to create: %s", SDL_GetError());
	// 	return;
	// }
}

void initGLContext() {
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 4);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 5);
	SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
	SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

	globalGame.glContext = SDL_GL_CreateContext(globalGame.window);

	SDL_GL_SetSwapInterval(1); // vsync

}

void handlePrepareFrame() {
	// SDL_SetRenderDrawColor(globalGame.renderer, 96, 128, 255, 255);
	// SDL_RenderClear(globalGame.renderer);
	glClearColor(0.25, 0.5, 1.0, 1.0);
	glClear(GL_COLOR_BUFFER_BIT);
}

void handleInput() {
	SDL_Event event;
	while(SDL_PollEvent(&event)) {
		switch(event.type) {
			case SDL_QUIT:
				globalGame.queueGracefulExit = true;
			break;
			default:
			break;
		}
	}
}

void handlePresentFrame() {
	// SDL_RenderPresent(globalGame.renderer);	
	SDL_GL_SwapWindow(globalGame.window);
}

void handleCleanup() {
	SDL_DestroyRenderer(globalGame.renderer);
	SDL_GL_DeleteContext(globalGame.glContext);
	SDL_DestroyWindow(globalGame.window);
	SDL_Quit();
}

void main()
{
	DerelictGL3.load();
	DerelictSDL2.load();
	DerelictSDL2Image.load();
	DerelictSDL2Mixer.load();
	DerelictSDL2ttf.load();
	initSDL();
	initGLContext();
	// auto loaded = DerelictGL3.reload();

	Sprite _spr = new Sprite(new Rectangle());

	for(;;) {
		if(globalGame.queueGracefulExit) {
			break;
		}

		handlePrepareFrame();

		handleInput();

		handlePresentFrame();
	}

	handleCleanup();

	return;
}
