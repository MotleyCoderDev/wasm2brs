#define WIDTH 320
#define HEIGHT 200
unsigned char image[WIDTH * HEIGHT];

static unsigned char color(int iteration, int offset, int scale) {
  iteration = ((iteration * scale) + offset) % 1024;
  if (iteration < 256) {
    return iteration;
  } else if (iteration < 512) {
    return 255 - (iteration - 255);
  } else {
    return 0;
  }
}

static int iterate(double x0, double y0, int maxiterations) {
  double a = 0.0, b = 0.0, rx = 0.0, ry = 0.0;
  int iterations = 0;
  while (iterations < maxiterations && (rx * rx + ry * ry <= 4.0)) {
    rx = a * a - b * b + x0;
    ry = 2.0 * a * b + y0;
    a = rx;
    b = ry;
    iterations++;
  }
  return iterations;
}

static double scale(double domainStart, double domainLength, int screenLength, int step) {
  return domainStart + domainLength * ((double)(step - screenLength) / (double)screenLength);
}

__attribute__((__export_name__("mandelbrot")))
void* mandelbrot(int maxIterations, double cx, double cy, double diameter) {
  double verticalDiameter = diameter * HEIGHT / WIDTH;
  for(int y = 0; y < HEIGHT; y++) {
    for(int x = 0; x < WIDTH; x++) {
      const double rx = scale(cx, diameter, WIDTH, x);
      const double ry = scale(cy, verticalDiameter, HEIGHT, y);
      const int iterations = iterate(rx, ry, maxIterations);
      const int idx = (x + y * WIDTH) * 4;
      const unsigned char r = iterations == maxIterations ? 0 : color(iterations, 0, 4);
      const unsigned char g = iterations == maxIterations ? 0 : color(iterations, 128, 4);
      const unsigned char b = iterations == maxIterations ? 0 : color(iterations, 356, 4);

      image[idx + 3] = r;
      image[idx + 2] = g;
      image[idx + 1] = b;
      image[idx + 0] = 0xFF;
    }
  }
  return image;
}
