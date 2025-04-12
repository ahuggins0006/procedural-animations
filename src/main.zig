const rl = @import("raylib");
const std = @import("std");

const Ball = struct {
    position: rl.Vector2,
    velocity: rl.Vector2,
    radius: f32,
    color: rl.Color,
    lifetime: f32,
};

pub fn main() anyerror!void {
    // Initialization
    //--------------------------------------------------------------------------------------
    const screenWidth = 800;
    const screenHeight = 450;
    rl.initWindow(screenWidth, screenHeight, "raylib-zig [core] example - bouncing balls");
    defer rl.closeWindow(); // Close window and OpenGL context
    rl.setTargetFPS(60); // Set our game to run at 60 frames-per-second

    var prng = std.Random.DefaultPrng.init(@intCast(std.time.milliTimestamp()));
    var rand = prng.random();

    var balls = std.ArrayList(Ball).init(std.heap.page_allocator);
    defer balls.deinit();

    // Constants
    const gravity: f32 = 400.0;
    const ballSpawnInterval: f32 = 0.5; // seconds
    const maxLifetime: f32 = 5.0; // seconds
    var timer: f32 = 0.0;

    //--------------------------------------------------------------------------------------
    // Main game loop
    while (!rl.windowShouldClose()) { // Detect window close button or ESC key
        // Update
        //----------------------------------------------------------------------------------
        const deltaTime = rl.getFrameTime();
        timer += deltaTime;

        // Spawn new ball
        if (timer >= ballSpawnInterval) {
            timer = 0.0;

            // Create a ball with random velocity
            const ballVelocityRange: f32 = 200.0;
            const ball = Ball{
                .position = .{ .x = @as(f32, @floatFromInt(screenWidth)) / 2.0, .y = @as(f32, @floatFromInt(screenHeight)) / 2.0 },
                .velocity = .{ .x = (rand.float(f32) * 2.0 - 1.0) * ballVelocityRange, .y = (rand.float(f32) * 2.0 - 1.0) * ballVelocityRange },
                .radius = 20.0,
                .color = rl.Color{ // White color
                    .r = 255,
                    .g = 255,
                    .b = 255,
                    .a = 255,
                },
                .lifetime = 0.0,
            };

            try balls.append(ball);
        }

        // Update balls
        var i: usize = 0;
        while (i < balls.items.len) {
            // Update lifetime
            balls.items[i].lifetime += deltaTime;
            if (balls.items[i].lifetime >= maxLifetime) {
                // Remove ball if lifetime exceeded
                _ = balls.orderedRemove(i);
                continue;
            }

            // Apply gravity
            balls.items[i].velocity.y += gravity * deltaTime;

            // Update position
            balls.items[i].position.x += balls.items[i].velocity.x * deltaTime;
            balls.items[i].position.y += balls.items[i].velocity.y * deltaTime;

            // Check for collisions with edges
            const ballRight = balls.items[i].position.x + balls.items[i].radius;
            const ballLeft = balls.items[i].position.x - balls.items[i].radius;
            const ballBottom = balls.items[i].position.y + balls.items[i].radius;
            const ballTop = balls.items[i].position.y - balls.items[i].radius;

            // Right edge collision
            if (ballRight >= @as(f32, @floatFromInt(screenWidth))) {
                balls.items[i].position.x = @as(f32, @floatFromInt(screenWidth)) - balls.items[i].radius;
                balls.items[i].velocity.x *= -0.9; // Bounce with some energy loss
            }

            // Left edge collision
            if (ballLeft <= 0) {
                balls.items[i].position.x = balls.items[i].radius;
                balls.items[i].velocity.x *= -0.9; // Bounce with some energy loss
            }

            // Bottom edge collision
            if (ballBottom >= @as(f32, @floatFromInt(screenHeight))) {
                balls.items[i].position.y = @as(f32, @floatFromInt(screenHeight)) - balls.items[i].radius;
                balls.items[i].velocity.y *= -0.9; // Bounce with some energy loss
            }

            // Top edge collision
            if (ballTop <= 0) {
                balls.items[i].position.y = balls.items[i].radius;
                balls.items[i].velocity.y *= -0.9; // Bounce with some energy loss
            }

            i += 1;
        }

        //----------------------------------------------------------------------------------
        // Draw
        //----------------------------------------------------------------------------------
        rl.beginDrawing();
        defer rl.endDrawing();
        rl.clearBackground(.black); // Changed to black background

        // Draw all balls
        for (balls.items) |ball| {
            const transparencyFactor = 255.0 * (1.0 - (ball.lifetime / maxLifetime));
            var ballColor = ball.color;
            ballColor.a = @as(u8, @intFromFloat(transparencyFactor));
            rl.drawCircleV(ball.position, ball.radius, ballColor);
        }

        // Draw ball count - changed to white text for visibility on black background
        const ballCountText = std.fmt.allocPrintZ(std.heap.page_allocator, "Balls: {d}", .{balls.items.len}) catch "Balls: ?";
        defer std.heap.page_allocator.free(ballCountText);
        rl.drawText(ballCountText, 10, 10, 20, .white);
        //----------------------------------------------------------------------------------
    }
}
