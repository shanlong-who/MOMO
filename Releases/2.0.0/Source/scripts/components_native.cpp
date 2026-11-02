#include <vector>
#include <algorithm>
#define R_NO_REMAP
#include <R.h>
#include <Rinternals.h>

struct Component { int id, area, xmin, xmax, ymin, ymax; double cx, cy; };

// A small build-time helper called by R; never distributed with the pet EXEs.
extern "C" __declspec(dllexport) SEXP label_components(SEXP alpha, SEXP threshold) {
    SEXP dimensions = Rf_getAttrib(alpha, R_DimSymbol);
    int height = INTEGER(dimensions)[0], width = INTEGER(dimensions)[1];
    double cutoff = Rf_asReal(threshold);
    SEXP labels = PROTECT(Rf_allocMatrix(INTSXP, height, width));
    int* label_data = INTEGER(labels);
    std::fill(label_data, label_data + height * width, 0);
    const double* values = REAL(alpha);
    std::vector<Component> objects;
    std::vector<int> queue;
    int label = 0;
    for (int x = 0; x < width; ++x) for (int y = 0; y < height; ++y) {
        int index = x * height + y;
        if (values[index] <= cutoff || label_data[index]) continue;
        ++label; queue.clear(); queue.push_back(index); label_data[index] = label;
        int left = x, right = x, top = y, bottom = y;
        double sx = 0, sy = 0;
        for (size_t next = 0; next < queue.size(); ++next) {
            int at = queue[next], px = at / height, py = at % height;
            left = std::min(left, px); right = std::max(right, px);
            top = std::min(top, py); bottom = std::max(bottom, py);
            sx += px; sy += py;
            for (int dx = -1; dx <= 1; ++dx) for (int dy = -1; dy <= 1; ++dy) {
                int nx = px + dx, ny = py + dy;
                if (nx < 0 || nx >= width || ny < 0 || ny >= height) continue;
                int neighbor = nx * height + ny;
                if (!label_data[neighbor] && values[neighbor] > cutoff) {
                    label_data[neighbor] = label; queue.push_back(neighbor);
                }
            }
        }
        objects.push_back({label, int(queue.size()), left, right, top, bottom,
                           sx / queue.size(), sy / queue.size()});
    }
    int count = int(objects.size());
    SEXP components = PROTECT(Rf_allocMatrix(REALSXP, count, 8));
    double* output = REAL(components);
    for (int i = 0; i < count; ++i) {
        const Component& c = objects[i];
        double row[] = {double(c.id), double(c.area), double(c.xmin), double(c.xmax),
                        double(c.ymin), double(c.ymax), c.cx, c.cy};
        for (int j = 0; j < 8; ++j) output[i + j * count] = row[j];
    }
    SEXP result = PROTECT(Rf_allocVector(VECSXP, 2));
    SEXP names = PROTECT(Rf_allocVector(STRSXP, 2));
    SET_VECTOR_ELT(result, 0, labels); SET_VECTOR_ELT(result, 1, components);
    SET_STRING_ELT(names, 0, Rf_mkChar("labels")); SET_STRING_ELT(names, 1, Rf_mkChar("components"));
    Rf_setAttrib(result, R_NamesSymbol, names);
    UNPROTECT(4);
    return result;
}
