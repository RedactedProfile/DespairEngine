/*
 * Despair Engine
 * ----------------------------------------------------------------------------
 * Filename:    app.d
 * Description: Right now everthing pretty much goes here. That will change at a later date. 
 * Created by:  Kyle Harrison (redactedprofile@gmail.com)
 * Date:        2024
 * 
 * ----------------------------------------------------------------------------
 * Copyright (c) 2024 Ninja Ghost, Kyle Harrison
 * 
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 * 
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 * 
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 * ----------------------------------------------------------------------------
 */

import std.stdio;
import derelict.sdl2.sdl;
import derelict.sdl2.image;
import derelict.sdl2.mixer;
import derelict.sdl2.ttf;
import derelict.opengl;
mixin glFreeFuncs!(GLVersion.gl45);
import gl3n.math;
import gl3n.linalg;
// note about gl3n vs glm, something to keep in mind: https://forum.dlang.org/post/qothvgbpudxnrkkcmxde@forum.dlang.org
//   > iirc, gl3n uses row major and glm uses column major ordering
//   > just pass GL_TRUE to the transpose argument in glUniformMatrix4fv
alias vec3r = Vector!(real, 3);


enum uint MAX_MESH_VERTS = 2048;
enum uint MAX_MESH_INDICES = MAX_MESH_VERTS * 2;
enum uint MAX_MODEL_MESHES = 8;



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
	float[] uvs   = [];
	int[] indices = [];

	uint vertexBufferObject = 0;
	uint indexBufferObject = 0;

	vec3 position = vec3(0f,0f,0f);
	vec3r rotation = vec3r(0f,1f,0f);
	vec3 scale = vec3(1f,1f,1f);
	
	mat4 transform = mat4.identity;

	this() {
		
	}
}

class Rectangle : Primitive
{
	float[4] verts = [];
}

class Mesh : Primitive
{
	float[MAX_MESH_VERTS] verts = []; 
	float[MAX_MESH_VERTS] uvs = [];
	float[MAX_MESH_VERTS] indices = [];

	this() {
		super();
	}

}

// Collected Resources made to be a paintable object to screen
class GameObject
{
	Primitive primitive;
	uint vertexArrayObject;

	vec3 position = vec3(0f,0f,0f);
	vec3r rotation = vec3r(0f,1f,0f);
	vec3 scale = vec3(1f,1f,1f);
	
	mat4 transform = mat4.identity;
}

// Sprite is a flat plane with a texture that always faces the camera
class Sprite : GameObject
{
	SDL_Surface *img;
	
	this(Primitive _prim) {
		this.primitive = _prim;
	}
}

// Model is a collection of Meshes that represent a single entity
class Model : GameObject 
{
	Mesh[MAX_MODEL_MESHES] meshes = [];

	this() {

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
