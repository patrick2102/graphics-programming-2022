#include <glad/glad.h>
#include <GLFW/glfw3.h>

#include <shader.h>

#include <iostream>
#include <vector>
#include <math.h>

// structure to hold the info necessary to render an object
struct SceneObject {
    unsigned int VAO;           // vertex array object handle
    unsigned int vertexCount;   // number of vertices in the object
    float r, g, b;              // for object color
    float x, y;                 // for position offset
};

// declaration of the function you will implement in exercise 2.1
SceneObject instantiateCone(float r, float g, float b, float offsetX, float offsetY);
// mouse, keyboard and screen reshape glfw callbacks
void button_input_callback(GLFWwindow* window, int button, int action, int mods);
void key_input_callback(GLFWwindow* window, int button, int other,int action, int mods);
void framebuffer_size_callback(GLFWwindow* window, int width, int height);

// settings
const unsigned int SCR_WIDTH = 600;
const unsigned int SCR_HEIGHT = 600;

// global variables we will use to store our objects, shaders, and active shader
std::vector<SceneObject> sceneObjects;
std::vector<Shader> shaderPrograms;
Shader* activeShader;


int main()
{
    // glfw: initialize and configure
    glfwInit();
    glfwWindowHint(GLFW_CONTEXT_VERSION_MAJOR, 3);
    glfwWindowHint(GLFW_CONTEXT_VERSION_MINOR, 3);
    glfwWindowHint(GLFW_OPENGL_PROFILE, GLFW_OPENGL_CORE_PROFILE);

#ifdef __APPLE__
    glfwWindowHint(GLFW_OPENGL_FORWARD_COMPAT, GL_TRUE); // uncomment this statement to fix compilation on OS X
#endif

    // glfw window creation
    GLFWwindow* window = glfwCreateWindow(SCR_WIDTH, SCR_HEIGHT, "Exercise 2 - Voronoi Diagram", NULL, NULL);
    if (window == NULL)
    {
        std::cout << "Failed to create GLFW window" << std::endl;
        glfwTerminate();
        return -1;
    }
    glfwMakeContextCurrent(window);
    // setup frame buffer size callback
    glfwSetFramebufferSizeCallback(window, framebuffer_size_callback);
    // setup input callbacks
    glfwSetMouseButtonCallback(window, button_input_callback); // NEW!
    glfwSetKeyCallback(window, key_input_callback); // NEW!

    // glad: load all OpenGL function pointers
    if (!gladLoadGLLoader((GLADloadproc)glfwGetProcAddress))
    {
        std::cout << "Failed to initialize GLAD" << std::endl;
        return -1;
    }

    // NEW!
    // build and compile the shader programs
    shaderPrograms.push_back(Shader("shaders/shader.vert", "shaders/color.frag"));
    shaderPrograms.push_back(Shader("shaders/shader.vert", "shaders/distance.frag"));
    shaderPrograms.push_back(Shader("shaders/shader.vert", "shaders/distance_color.frag"));
    activeShader = &shaderPrograms[0];

    // NEW!
    // set up the z-buffer
    glDepthRange(1,-1); // make the NDC a right handed coordinate system, with the camera pointing towards -z
    glEnable(GL_DEPTH_TEST); // turn on z-buffer depth test
    glDepthFunc(GL_LESS); // draws fragments that are closer to the screen in NDC

    // TODO exercise 2.6
    // enable blending
    // choose the right blending factors to produce additive blending
    // glBlendFunc(?, ?);

    // render loop
    while (!glfwWindowShouldClose(window)) {
        // background color
        glClearColor(0.0f, 0.0f, 0.0f, 1.0f);
        // notice that now we are clearing two buffers, the color and the z-buffer
        glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

        // render the cones
        glUseProgram(activeShader->ID);

        // Iterate through the scene objects, for each object:
        // - bind the VAO; set the uniform variables; and draw.
        for(auto sc : sceneObjects){
            glBindVertexArray(sc.VAO);

            int locationPos = glGetUniformLocation(activeShader->ID, "uPos");
            int locationCol = glGetUniformLocation(activeShader->ID, "cCol");
            glUniform2f(locationPos, sc.x, sc.y);
            glUniform3f(locationCol, sc.r, sc.g, sc.b);

            glDrawArrays(GL_TRIANGLES, 0, sc.vertexCount);
        }


        // glfw: swap buffers and poll IO events (keys pressed/released, mouse moved etc.)
        glfwSwapBuffers(window);
        glfwPollEvents();
    }

    // glfw: terminate, clearing all previously allocated GLFW resources.
    glfwTerminate();
    return 0;
}


// creates a cone triangle mesh, uploads it to openGL and returns the VAO associated to the mesh
SceneObject instantiateCone(float r, float g, float b, float offsetX, float offsetY){
    //TODO solved using 1.7, maybe do it with 1.8 later

    // Create an instance of a SceneObject,
    SceneObject sceneObject{};

    // you will need to store offsetX, offsetY, r, g and b in the object.
    sceneObject.x = offsetX;
    sceneObject.y = offsetY;
    sceneObject.r = r;
    sceneObject.g = g;
    sceneObject.b = b;

    // Build the geometry into an std::vector<float> or float array.
    std::vector<float> vboVec;
    float numOfTriangles = 16;

    for(int i = 0; i < (int)numOfTriangles; i++){
        float p1x = cos(((float)i/numOfTriangles)*3.1415f*2)/2;
        float p1y = sin(((float)i/numOfTriangles)*3.1415f*2)/2;


        float p2x = cos(((float)(i+1)/numOfTriangles)*3.1415f*2)/2;
        float p2y = sin(((float)(i+1)/numOfTriangles)*3.1415f*2)/2;

        vboVec.insert(vboVec.end(), {0.0f, 0.0f, 1.0f});
        vboVec.insert(vboVec.end(), {p1x, p1y, 0.0f});
        vboVec.insert(vboVec.end(), {p2x, p2y, 0.0f});
    }

    // Store the number of vertices in the mesh in the scene object.
    sceneObject.vertexCount = (int)numOfTriangles * 3;

    // Declare and generate a VAO and VBO (and an EBO if you decide the work with indices).
    unsigned int VAO, VBO;
    glGenVertexArrays(1, &VAO);
    glGenBuffers(1, &VBO);

    // Bind and set the VAO and VBO (and optionally a EBO) in the correct order.
    glBindVertexArray(VAO);
    glBindBuffer(GL_ARRAY_BUFFER, VBO);
    glBufferData(GL_ARRAY_BUFFER, vboVec.size() * sizeof(GLfloat), &vboVec[0], GL_STATIC_DRAW);

    // Set the position attribute pointers in the shader.
    int posSize = 3;
    int posAttributeLocation = 0;
    glVertexAttribPointer(posAttributeLocation, posSize, GL_FLOAT, GL_FALSE, 0, 0);
    glEnableVertexAttribArray(posAttributeLocation);

    // Store the VAO handle in the scene object.
    sceneObject.VAO = VAO;

    // 'return' the scene object for the cone instance you just created.
    return sceneObject;
}

// glfw: called whenever a mouse button is pressed
void button_input_callback(GLFWwindow* window, int button, int action, int mods){
    // (exercises 1.9 and 2.2 can help you with implementing this function)

    // Test button press, see documentation at:
    //     https://www.glfw.org/docs/latest/input_guide.html#input_mouse_button
    // CODE HERE
    // If a left mouse button press was detected, call instantiateCone:
    // - Push the return value to the back of the global 'vector<SceneObject> sceneObjects'.
    // - The click position should be transformed from screen coordinates to normalized device coordinates,
    //   to obtain the offset values that describe the position of the object in the screen plane.
    // - A random value in the range [0, 1] should be used for the r, g and b variables.

    if(button == 0){
        double r = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);
        double g = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);
        double b = static_cast <float> (rand()) / static_cast <float> (RAND_MAX);

        double xPos;
        double yPos;
        glfwGetCursorPos(window, &xPos, &yPos);

        double xndc = xPos/SCR_WIDTH * 2 - 1;
        double yndc = yPos/SCR_HEIGHT * -2 + 1;

        auto cone = instantiateCone(r, g, b, xndc, yndc);

        sceneObjects.push_back(cone);
    }

}

// glfw: called whenever a keyboard key is pressed
void key_input_callback(GLFWwindow* window, int button, int other,int action, int mods){
    // TODO exercise 2.4

    // Set the activeShader variable by detecting when the keys 1, 2 and 3 were pressed;
    // see documentation at https://www.glfw.org/docs/latest/input_guide.html#input_keyboard
    // Key 1 sets the activeShader to &shaderPrograms[0];
    //   and so on.
    // CODE HERE
}


// glfw: whenever the window size changed (by OS or user resize) this callback function executes
void framebuffer_size_callback(GLFWwindow* window, int width, int height)
{
    // make sure the viewport matches the new window dimensions; note that width and
    // height will be significantly larger than specified on retina displays.
    glViewport(0, 0, width, height);
}