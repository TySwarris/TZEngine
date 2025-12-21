const std = @import("std");
const math = @import("zmath");
const glfw = @import("../../glfw.zig").glfw;
const Camera = @import("../../core/Camera.zig").Camera;

pub const OrthographicCamera = struct {
    cam: Camera,
    width: f32,
    height: f32,
    near: f32,
    far: f32,

    pub fn init(allocator: std.mem.Allocator, distance: f32, width: f32, height: f32, near: f32, far: f32) OrthographicCamera {
        return .{
            .cam = Camera.init(allocator, distance),
            .width = width,
            .height = height,
            .near = near,
            .far = far,
        };
    }

    pub fn update(self: *OrthographicCamera, window: ?*glfw.GLFWwindow, dt: f32) void {
        const speed: f32 = 10.0;
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_UP) == glfw.GLFW_PRESS) {
            self.cam.sceneObject.translateLocal(0, speed * dt, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_DOWN) == glfw.GLFW_PRESS) {
            self.cam.sceneObject.translateLocal(0, -speed * dt, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_LEFT) == glfw.GLFW_PRESS) {
            self.cam.sceneObject.translateLocal(-speed * dt, 0.0, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_RIGHT) == glfw.GLFW_PRESS) {
            self.cam.sceneObject.translateLocal(speed * dt, 0, 0);
        }
        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_K) == glfw.GLFW_PRESS) {
            if (self.width > 50 * dt) {
                self.width -= 50 * dt;
                self.height -= 50 * dt;
            }
        }

        if (glfw.glfwGetKey(window, glfw.GLFW_KEY_J) == glfw.GLFW_PRESS) {
            self.height += 50 * dt;
            self.width += 50 * dt;
        }
    }

    pub fn getProjectionMatrix(self: *const OrthographicCamera) math.Mat {

        //return math.orthographicRhGl(2.0, 2.0, -1.0, 1.0);
        return math.orthographicRhGl(self.width, self.height, self.near, self.far);
    }
};
