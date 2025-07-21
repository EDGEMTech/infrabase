#include <stdio.h>
#include <stdlib.h>
#include <time.h>

#include "common.h"
#include "esUtil.h"

int32_t screen_width = 0;
int32_t screen_height = 0;

GLubyte *texture_data = NULL;  // Global or static pointer
GLuint texture;

static struct {
    struct egl egl;
    GLfloat aspect;
    GLuint program;
    GLint modelviewmatrix, modelviewprojectionmatrix, normalmatrix;
    GLuint vbo;
    GLuint positionsoffset, colorsoffset, normalsoffset;
    GLuint texture;  // Declare the texture variable
} gl;

static const GLfloat vVertices[] = {
    -1.0f, -1.0f, 0.0f,  
     1.0f, -1.0f, 0.0f,  
    -1.0f,  1.0f, 0.0f,  
     1.0f,  1.0f, 0.0f   
};

static const GLfloat vTexCoords[] = {
    0.0f, 0.0f,
    1.0f, 0.0f,
    0.0f, 1.0f,
    1.0f, 1.0f
};

// Vertex shader
static const char *vertex_shader_source =
    "attribute vec4 in_position;        \n"
    "attribute vec2 in_texcoord;        \n"
    "varying vec2 texcoord;             \n"
    "void main()                        \n"
    "{                                  \n"
    "    gl_Position = in_position;     \n"
    "    texcoord = in_texcoord;        \n"
    "}                                  \n";

// Fragment shader
static const char *fragment_shader_source =
    "precision mediump float;             \n"
    "uniform sampler2D rect_texture;     \n"
    "varying vec2 texcoord;              \n"
    "void main()                         \n"
    "{                                   \n"
    "    gl_FragColor = texture2D(rect_texture, texcoord); \n"
    "}                                   \n";

// Function to generate random RGBA values
void generate_gradient(GLubyte *data, int width, int height) {
	static uint8_t color = 0; 

	memset(data, color, width * height * 4);
	color++;
}

static void draw_cube_smooth(unsigned i)
{
    // Generate random data for the texture
    generate_gradient(texture_data, screen_width, screen_height);

    // Update the texture with the new data
    glTexSubImage2D(GL_TEXTURE_2D, 0, 0, 0, screen_width, screen_height, GL_RGBA, GL_UNSIGNED_BYTE, texture_data);

    // Draw the object with the updated texture
    glDrawArrays(GL_TRIANGLE_STRIP, 0, 4);
}


const struct egl * init_cube_smooth(const struct gbm *gbm, int samples)
{
    int ret;

    ret = init_egl(&gl.egl, gbm, samples);
    if (ret)
        return NULL;
    gl.aspect = (GLfloat)(gbm->height) / (GLfloat)(gbm->width);

	screen_height = gbm->height;
	screen_width = gbm->width;

    ret = create_program(vertex_shader_source, fragment_shader_source);
    if (ret < 0)
        return NULL;

    gl.program = ret;

    glBindAttribLocation(gl.program, 0, "in_position");
    glBindAttribLocation(gl.program, 1, "in_texcoord");

    ret = link_program(gl.program);
    if (ret)
        return NULL;

    glUseProgram(gl.program);

	texture_data = (GLubyte *)malloc(screen_width * screen_height * 4);  // width * height * RGBA channels
    if (!texture_data) {
        // Handle memory allocation failure
        return NULL; 
    }

    // Create a texture
    glGenTextures(1, &gl.texture);
    glBindTexture(GL_TEXTURE_2D, gl.texture);
	texture = gl.texture;

    // Set texture parameters
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
    glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);

    // Initially, we upload a blank texture (can be updated later)
    glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, gbm->width, gbm->height, 0, GL_RGBA, GL_UNSIGNED_BYTE, NULL);

    GLint rect_texture_location = glGetUniformLocation(gl.program, "rect_texture");
    glUniform1i(rect_texture_location, 0);  // Bind texture to texture unit 0

    glViewport(0, 0, gbm->width, gbm->height);
    glEnable(GL_CULL_FACE);

    gl.positionsoffset = 0;
    gl.colorsoffset = sizeof(vVertices);
    gl.normalsoffset = sizeof(vVertices) + sizeof(vTexCoords);
    glGenBuffers(1, &gl.vbo);
    glBindBuffer(GL_ARRAY_BUFFER, gl.vbo);
    glBufferData(GL_ARRAY_BUFFER, sizeof(vVertices) + sizeof(vTexCoords), NULL, GL_STATIC_DRAW);
    glBufferSubData(GL_ARRAY_BUFFER, gl.positionsoffset, sizeof(vVertices), vVertices);
    glBufferSubData(GL_ARRAY_BUFFER, gl.colorsoffset, sizeof(vTexCoords), vTexCoords);

    glVertexAttribPointer(0, 3, GL_FLOAT, GL_FALSE, 0, (const GLvoid *)(intptr_t)gl.positionsoffset);
    glEnableVertexAttribArray(0);

    glVertexAttribPointer(1, 2, GL_FLOAT, GL_FALSE, 0, (const GLvoid *)(intptr_t)gl.colorsoffset);
    glEnableVertexAttribArray(1);

    gl.egl.draw = draw_cube_smooth;

    return &gl.egl;
}
