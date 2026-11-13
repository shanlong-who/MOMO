// Dragon Offline: native Windows desktop companion, with embedded artwork.
// Copyright (c) 2026 Shanlong Ding. MIT License.
#ifndef UNICODE
#define UNICODE
#endif
#ifndef _UNICODE
#define _UNICODE
#endif
#define NOMINMAX
#include <windows.h>
#include <windowsx.h>
#include <gdiplus.h>
#include <shlobj.h>
#include <shellapi.h>
#include <algorithm>
#include <cmath>
#include <cstdint>
#include <cwctype>
#include <cstring>
#include <memory>
#include <stdexcept>
#include <string>
#include <vector>

static const wchar_t* PET = L"Dragon";
static const int HOME_OFFSET = 20;
// Six idle animation frames plus the desktop format's neutral cell.
static const int COUNTS[] = {7, 8, 8, 4, 5, 8, 6, 6, 6, 8, 8};
static const int SIZES[] = {144, 192, 240, 288};
static const UINT IPC = WM_APP + 71;
enum Command { HELLO = 101, JUMP, PLAY, STRETCH, REST, PAUSE, WANDER,
               FOLLOW, TOPMOST, HOME, ABOUT, QUIT, SIZE_FIRST = 201, SNAPSHOT = 301 };

static void require(bool ok, const char* message) {
    if (!ok) throw std::runtime_error(message);
}
static double now_seconds() { return GetTickCount64() / 1000.0; }
static double frame_delay(int row, int column) {
    static const double idle[] = {1.6, 0.50, 0.12, 0.12, 0.35, 0.90};
    static const double hello[] = {0.30, 0.55, 0.40, 0.60};
    static const double lift[] = {0.30, 0.30, 0.45, 0.35, 0.50};
    static const double concern[] = {0.25, 0.35, 0.35, 0.45, 0.45, 0.45, 0.40, 0.50};
    static const double waiting[] = {0.50, 0.65, 0.40, 0.50, 0.55, 0.60};
    static const double thinking[] = {0.45, 0.65, 0.45, 0.60, 0.60, 0.50};
    static const double review[] = {0.40, 0.50, 0.50, 0.50, 0.45, 0.45};
    switch (row) {
    case 0: return idle[column % 6];
    case 1: case 2: return 0.22;
    case 3: return hello[column];
    case 4: return lift[column];
    case 5: return concern[column];
    case 6: return waiting[column];
    case 7: return thinking[column];
    case 8: return review[column];
    default: return 0.25;
    }
}
static double action_duration(int row) {
    double seconds = 0.25;
    for (int column = 0; column < COUNTS[row]; ++column) seconds += frame_delay(row, column);
    return seconds;
}
static bool valid_size(int value) {
    return std::find(std::begin(SIZES), std::end(SIZES), value) != std::end(SIZES);
}
static POINT clamp_point(POINT p, int width, int height, RECT area) {
    p.x = std::max(area.left, std::min(p.x, std::max(area.left, area.right - width)));
    p.y = std::max(area.top, std::min(p.y, std::max(area.top, area.bottom - height)));
    return p;
}
static RECT work_area(POINT p) {
    MONITORINFO info = {sizeof(info), {}, {}, 0};
    GetMonitorInfoW(MonitorFromPoint(p, MONITOR_DEFAULTTONEAREST), &info);
    return info.rcWork;
}
static int look_direction(double dx, double dy) {
    int result = int(std::lround(std::atan2(dx, -dy) * 8.0 / 3.141592653589793));
    return (result + 16) % 16;
}
static void write_text(const std::wstring& path, const std::string& text) {
    HANDLE file = CreateFileW(path.c_str(), GENERIC_WRITE, FILE_SHARE_READ, nullptr,
                              CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, nullptr);
    require(file != INVALID_HANDLE_VALUE, "Could not write the local report.");
    DWORD written = 0;
    BOOL ok = WriteFile(file, text.data(), DWORD(text.size()), &written, nullptr);
    CloseHandle(file);
    require(ok && written == text.size(), "Could not finish writing the local report.");
}
static std::wstring widen(const std::string& value) {
    return std::wstring(value.begin(), value.end());
}
static std::wstring make_directory(const std::wstring& path) {
    int result = SHCreateDirectoryExW(nullptr, path.c_str(), nullptr);
    require(result == ERROR_SUCCESS || result == ERROR_ALREADY_EXISTS || result == ERROR_FILE_EXISTS,
            "Could not create the local settings directory.");
    return path;
}
static std::wstring default_data_dir() {
    wchar_t path[MAX_PATH];
    require(SUCCEEDED(SHGetFolderPathW(nullptr, CSIDL_LOCAL_APPDATA, nullptr, 0, path)),
            "Could not locate the local user data directory.");
    return std::wstring(path) + L"\\DesktopPetsLite\\" + PET;
}
static uint32_t path_hash(const std::wstring& path) {
    uint32_t hash = 2166136261u;
    for (wchar_t c : path) { hash ^= uint32_t(towlower(c)); hash *= 16777619u; }
    return hash;
}

struct Preferences {
    int size = 192;
    POINT position = {LONG_MIN, LONG_MIN};
    bool paused = false, wander = true, follow = true, topmost = true;
    void load(const std::wstring& path) {
        int value = int(GetPrivateProfileIntW(L"Pet", L"Size", size, path.c_str()));
        if (valid_size(value)) size = value;
        const wchar_t* keys[] = {L"Paused", L"Wander", L"Follow", L"Topmost"};
        bool* values[] = {&paused, &wander, &follow, &topmost};
        for (int i = 0; i < 4; ++i) {
            value = int(GetPrivateProfileIntW(L"Pet", keys[i], *values[i], path.c_str()));
            if (value == 0 || value == 1) *values[i] = value != 0;
        }
        int x = int(GetPrivateProfileIntW(L"Pet", L"X", LONG_MIN, path.c_str()));
        int y = int(GetPrivateProfileIntW(L"Pet", L"Y", LONG_MIN, path.c_str()));
        if (x > -100000 && x < 100000 && y > -100000 && y < 100000) position = {x, y};
    }
    void save(const std::wstring& path) const {
        std::string text = "[Pet]\r\nSize=" + std::to_string(size) +
            "\r\nX=" + std::to_string(position.x) + "\r\nY=" + std::to_string(position.y) +
            "\r\nPaused=" + std::to_string(paused) + "\r\nWander=" + std::to_string(wander) +
            "\r\nFollow=" + std::to_string(follow) + "\r\nTopmost=" + std::to_string(topmost) + "\r\n";
        std::wstring temporary = path + L".tmp";
        write_text(temporary, text);
        require(MoveFileExW(temporary.c_str(), path.c_str(), MOVEFILE_REPLACE_EXISTING | MOVEFILE_WRITE_THROUGH),
                "Could not save pet preferences.");
        WritePrivateProfileStringW(nullptr, nullptr, nullptr, path.c_str());
    }
};

struct Artwork {
    IStream* stream = nullptr;
    std::unique_ptr<Gdiplus::Bitmap> atlas;
    int cell_width = 0, cell_height = 0;
    Artwork() {
        HRSRC resource = FindResourceW(nullptr, MAKEINTRESOURCEW(101), RT_RCDATA);
        require(resource != nullptr, "The embedded artwork is missing.");
        DWORD bytes = SizeofResource(nullptr, resource);
        HGLOBAL copy = GlobalAlloc(GMEM_MOVEABLE, bytes);
        require(copy != nullptr, "Not enough memory for the artwork.");
        void* target = GlobalLock(copy);
        std::memcpy(target, LockResource(LoadResource(nullptr, resource)), bytes);
        GlobalUnlock(copy);
        if (FAILED(CreateStreamOnHGlobal(copy, TRUE, &stream))) {
            GlobalFree(copy); throw std::runtime_error("Could not load the embedded artwork.");
        }
        atlas.reset(Gdiplus::Bitmap::FromStream(stream));
        require(atlas && atlas->GetLastStatus() == Gdiplus::Ok, "The embedded PNG is invalid.");
        require(atlas->GetWidth() % 8 == 0 && atlas->GetHeight() % 11 == 0,
                "The artwork grid is invalid.");
        cell_width = int(atlas->GetWidth() / 8);
        cell_height = int(atlas->GetHeight() / 11);
    }
    ~Artwork() { atlas.reset(); if (stream) stream->Release(); }
};

struct Surface {
    HDC dc = nullptr;
    HBITMAP bitmap = nullptr;
    HGDIOBJ old_bitmap = nullptr;
    BYTE* pixels = nullptr;
    std::unique_ptr<Gdiplus::Bitmap> canvas;
    int width = 0, height = 0;
    ~Surface() { clear(); }
    void clear() {
        canvas.reset();
        if (dc && old_bitmap) SelectObject(dc, old_bitmap);
        if (bitmap) DeleteObject(bitmap);
        if (dc) DeleteDC(dc);
        dc = nullptr; bitmap = nullptr; old_bitmap = nullptr; pixels = nullptr;
    }
    void resize(int w, int h) {
        if (w == width && h == height && dc) return;
        clear(); width = w; height = h;
        BITMAPINFO info = {};
        info.bmiHeader.biSize = sizeof(BITMAPINFOHEADER);
        info.bmiHeader.biWidth = w;
        info.bmiHeader.biHeight = -h;
        info.bmiHeader.biPlanes = 1;
        info.bmiHeader.biBitCount = 32;
        info.bmiHeader.biCompression = BI_RGB;
        dc = CreateCompatibleDC(nullptr);
        bitmap = CreateDIBSection(dc, &info, DIB_RGB_COLORS, reinterpret_cast<void**>(&pixels), nullptr, 0);
        require(dc && bitmap && pixels, "Could not create the transparent drawing surface.");
        old_bitmap = SelectObject(dc, bitmap);
        canvas.reset(new Gdiplus::Bitmap(w, h, PixelFormat32bppPARGB));
        require(canvas->GetLastStatus() == Gdiplus::Ok, "Could not create the animation canvas.");
    }
    void render(Artwork& art, int row, int column) {
        require(row >= 0 && row < 11 && column >= 0 && column < COUNTS[row], "Invalid animation frame.");
        {
            Gdiplus::Graphics graphics(canvas.get());
            graphics.SetCompositingMode(Gdiplus::CompositingModeSourceCopy);
            graphics.Clear(Gdiplus::Color(0, 0, 0, 0));
            graphics.SetInterpolationMode(Gdiplus::InterpolationModeHighQualityBicubic);
            graphics.SetPixelOffsetMode(Gdiplus::PixelOffsetModeHalf);
            auto status = graphics.DrawImage(art.atlas.get(), Gdiplus::Rect(0, 0, width, height),
                column * art.cell_width, row * art.cell_height, art.cell_width, art.cell_height, Gdiplus::UnitPixel);
            require(status == Gdiplus::Ok, "Could not draw an animation frame.");
        }
        // LockBits explicitly transfers GDI+'s completed premultiplied image
        // into the top-down Windows DIB used by UpdateLayeredWindow.
        Gdiplus::Rect bounds(0, 0, width, height);
        Gdiplus::BitmapData data = {};
        require(canvas->LockBits(&bounds, Gdiplus::ImageLockModeRead, PixelFormat32bppPARGB, &data) == Gdiplus::Ok,
                "Could not read the completed animation frame.");
        for (int y = 0; y < height; ++y)
            std::memcpy(pixels + y * width * 4, static_cast<BYTE*>(data.Scan0) + y * data.Stride, width * 4);
        canvas->UnlockBits(&data);
        // Discard subvisible alpha noise so empty desktop space stays click-through.
        for (int p = 0; p < width * height; ++p) {
            BYTE* pixel = pixels + p * 4;
            if (pixel[3] <= 3) std::memset(pixel, 0, 4);
        }
    }
};

struct PetWindow {
    HWND window = nullptr;
    Artwork& art;
    Surface surface;
    Preferences prefs;
    std::wstring data_dir, settings_path, smoke_report;
    int width = 192, height = 208, dpi = 96, row = 0, column = 0, direction = 1;
    int smoke_step = 0, displayed = 0, pending_look = -1;
    bool dragging = false, moved = false, suppress_click = false, menu_open = false, roaming = false;
    bool dirty = true, failed = false, smoke = false;
    POINT drag_pointer = {}, drag_origin = {}, last_pointer = {};
    double last_tick = now_seconds(), next_frame = 0, action_until = 0, next_action = 0, pointer_changed = 0;
    double exact_x = 0, pending_look_since = 0;
    uint32_t rng = GetTickCount() ^ GetCurrentProcessId();
    PetWindow(Artwork& artwork, std::wstring path) : art(artwork), data_dir(path) {
        settings_path = data_dir + L"\\preferences.ini";
        prefs.load(settings_path);
    }
    double random(double low, double high) {
        rng ^= rng << 13; rng ^= rng >> 17; rng ^= rng << 5;
        return low + (high - low) * (double(rng) / 4294967295.0);
    }
    void save() { prefs.save(settings_path); }
    void set_position(POINT p, bool clamp = true) {
        if (clamp) {
            POINT center = {p.x + width / 2, p.y + height / 2};
            p = clamp_point(p, width, height, work_area(center));
        }
        prefs.position = p;
        exact_x = p.x;
        SetWindowPos(window, nullptr, p.x, p.y, 0, 0, SWP_NOSIZE | SWP_NOZORDER | SWP_NOACTIVATE);
    }
    void resize(int logical_size) {
        int bottom = prefs.position.y == LONG_MIN ? 0 : prefs.position.y + height;
        prefs.size = logical_size;
        width = MulDiv(logical_size, dpi, 96);
        height = MulDiv(width, art.cell_height, art.cell_width);
        surface.resize(width, height);
        if (prefs.position.x != LONG_MIN) set_position({prefs.position.x, bottom - height});
        dirty = true;
    }
    void action(int new_row) {
        roaming = false; row = new_row; column = 0; dirty = true;
        double now = now_seconds();
        action_until = now + (new_row == 0 ? 0 : action_duration(new_row));
        next_frame = now + frame_delay(new_row, 0);
        next_action = action_until + random(45, 90);
    }
    void home() {
        POINT origin = {0, 0};
        RECT area = work_area(origin);
        set_position({area.right - width - MulDiv(HOME_OFFSET, dpi, 96), area.bottom - height - 12});
        action(3);
        ShowWindow(window, SW_SHOWNOACTIVATE);
        SetWindowPos(window, prefs.topmost ? HWND_TOPMOST : HWND_TOP, 0, 0, 0, 0,
                     SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE);
        save();
    }
    void paint() {
        surface.render(art, row, column);
        POINT source = {0, 0};
        SIZE size = {width, height};
        BLENDFUNCTION blend = {AC_SRC_OVER, 0, 255, AC_SRC_ALPHA};
        require(UpdateLayeredWindow(window, nullptr, &prefs.position, &size, surface.dc, &source, 0,
                                    &blend, ULW_ALPHA), "Windows could not display the transparent pet.");
        dirty = false; ++displayed;
    }
    void snapshot() {
        std::string text = "pid=" + std::to_string(GetCurrentProcessId()) +
            "\nsize=" + std::to_string(prefs.size) + "\nwidth=" + std::to_string(width) +
            "\nheight=" + std::to_string(height) + "\ndpi=" + std::to_string(dpi) +
            "\nx=" + std::to_string(prefs.position.x) + "\ny=" + std::to_string(prefs.position.y) +
            "\nrow=" + std::to_string(row) + "\ncolumn=" + std::to_string(column) +
            "\npaused=" + std::to_string(prefs.paused) + "\nwander=" + std::to_string(prefs.wander) +
            "\nfollow=" + std::to_string(prefs.follow) + "\ntopmost=" + std::to_string(prefs.topmost) +
            "\nframes=" + std::to_string(displayed) +
            "\nnext_auto_ms=" + std::to_string(int(std::max(0.0, next_action - now_seconds()) * 1000)) + "\n";
        write_text(data_dir + L"\\state.txt", text);
    }
    void command(int id) {
        if (id >= SIZE_FIRST && id < SIZE_FIRST + 4) { resize(SIZES[id - SIZE_FIRST]); save(); return; }
        switch (id) {
        case HELLO: prefs.paused = false; action(3); break;
        case JUMP: prefs.paused = false; action(4); break;
        case PLAY: prefs.paused = false; action(7); break;
        case STRETCH: prefs.paused = false; action(8); break;
        case REST: prefs.paused = false; action(5); break;
        case PAUSE: prefs.paused = !prefs.paused; roaming = false; next_action = now_seconds() + 45; break;
        case WANDER: prefs.wander = !prefs.wander; roaming = false; action(0); break;
        case FOLLOW: prefs.follow = !prefs.follow; action(0); break;
        case TOPMOST:
            prefs.topmost = !prefs.topmost;
            SetWindowPos(window, prefs.topmost ? HWND_TOPMOST : HWND_NOTOPMOST, 0, 0, 0, 0,
                         SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE); break;
        case HOME: home(); return;
        case ABOUT:
            MessageBoxW(window,
                L"Dragon Offline 2.0\n\nDrag: move\nClick: hello\nDouble-click: celebrate\n"
                L"Right-click: actions, size and exit\nOpen the EXE again: bring the pet home\n\n"
                L"A single native Windows app. No R or other runtime installation needed.\n"
                L"Works offline. Settings are saved in your local user profile.",
                (std::wstring(PET) + L" Offline").c_str(), MB_OK | MB_ICONINFORMATION); return;
        case QUIT: DestroyWindow(window); return;
        case SNAPSHOT: snapshot(); return;
        default: return;
        }
        save();
    }
    void menu(POINT point) {
        roaming = false; menu_open = true;
        HMENU popup = CreatePopupMenu();
        HMENU sizes = CreatePopupMenu();
        AppendMenuW(popup, MF_STRING | MF_DISABLED, 0, (std::wstring(PET) + L" Offline").c_str());
        AppendMenuW(popup, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(popup, MF_STRING, HELLO, L"Say hello");
        AppendMenuW(popup, MF_STRING, JUMP, L"Celebrate");
        AppendMenuW(popup, MF_STRING, PLAY, L"Think");
        AppendMenuW(popup, MF_STRING, STRETCH, L"Review");
        AppendMenuW(popup, MF_STRING, REST, L"Concern and recovery");
        AppendMenuW(popup, MF_SEPARATOR, 0, nullptr);
        auto check = [&](int id, const wchar_t* text, bool value) {
            AppendMenuW(popup, MF_STRING | (value ? MF_CHECKED : 0), id, text);
        };
        check(PAUSE, L"Pause animation", prefs.paused);
        check(WANDER, L"Occasional gliding", prefs.wander);
        check(FOLLOW, L"Look at cursor", prefs.follow);
        check(TOPMOST, L"Always on top", prefs.topmost);
        const wchar_t* labels[] = {L"Small", L"Medium", L"Large", L"Extra large"};
        for (int i = 0; i < 4; ++i)
            AppendMenuW(sizes, MF_STRING | (prefs.size == SIZES[i] ? MF_CHECKED : 0), SIZE_FIRST + i, labels[i]);
        AppendMenuW(popup, MF_POPUP, reinterpret_cast<UINT_PTR>(sizes), L"Size");
        AppendMenuW(popup, MF_STRING, HOME, (std::wstring(L"Bring ") + PET + L" home").c_str());
        AppendMenuW(popup, MF_STRING, ABOUT, L"About / Controls");
        AppendMenuW(popup, MF_SEPARATOR, 0, nullptr);
        AppendMenuW(popup, MF_STRING, QUIT, (std::wstring(L"Exit ") + PET).c_str());
        SetForegroundWindow(window);
        int id = TrackPopupMenu(popup, TPM_RETURNCMD | TPM_RIGHTBUTTON, point.x, point.y, 0, window, nullptr);
        DestroyMenu(popup);
        menu_open = false; next_action = now_seconds() + 45;
        if (id) command(id);
        if (IsWindow(window)) PostMessageW(window, WM_NULL, 0, 0);
    }
    void smoke_tick() {
        if (smoke_step < 74) {
            int offset = smoke_step; row = 0;
            while (offset >= COUNTS[row]) offset -= COUNTS[row++];
            column = offset; dirty = true;
        } else if (smoke_step < 78) {
            resize(SIZES[smoke_step - 74]); row = 0; column = 0;
        } else {
            require(displayed >= 78, "Smoke test did not display every frame and size.");
            write_text(smoke_report,
                "PASS: 73 animation/look frames, one neutral cell and four sizes shown using UpdateLayeredWindow.\n"
                "PASS: real native desktop window, per-pixel alpha and Windows event loop.\n");
            DestroyWindow(window); return;
        }
        ++smoke_step;
    }
    void tick() {
        double now = now_seconds();
        double seconds = std::min(0.1, now - last_tick); last_tick = now;
        if (smoke) smoke_tick();
        else if (!prefs.paused && !dragging && !menu_open) {
            POINT pointer; GetCursorPos(&pointer);
            if (pointer.x != last_pointer.x || pointer.y != last_pointer.y) {
                pointer_changed = now; last_pointer = pointer;
            }
            if (now >= action_until && row > 0 && row < 9) {
                roaming = false; row = 0; column = 0; dirty = true; next_frame = now + frame_delay(0, 0);
            }
            if (now >= next_action) {
                next_action = now + random(45, 90);
                double choice = random(0, 1);
                if (prefs.wander && choice < 0.22) {
                    direction = random(0, 1) < 0.5 ? -1 : 1;
                    row = direction == 1 ? 1 : 2; column = 0; roaming = true;
                    action_until = now + random(1.4, 2.4); next_frame = now + frame_delay(row, 0); dirty = true;
                } else if (choice < 0.50) {
                    const int actions[] = {3, 6, 7, 8};
                    action(actions[int(random(0, 3.999))]);
                }
            }
            if (roaming) {
                double desired = exact_x + direction * seconds * MulDiv(24, dpi, 96);
                POINT position = {LONG(std::lround(desired)), prefs.position.y};
                POINT bounded = clamp_point(position, width, height,
                    work_area({prefs.position.x + width / 2, prefs.position.y + height / 2}));
                if (bounded.x != position.x) { direction = -direction; row = direction == 1 ? 1 : 2; dirty = true; }
                set_position(bounded, false);
                exact_x = bounded.x == position.x ? desired : bounded.x;
            }
            bool looking = false;
            if (row == 0 || row >= 9) {
                double dx = pointer.x - prefs.position.x - width / 2.0;
                double dy = pointer.y - prefs.position.y - height / 3.0;
                double distance = std::hypot(dx, dy);
                looking = prefs.follow && now - pointer_changed < 3.0 && distance > width / 3 && distance < width * 4;
                if (looking) {
                    int look = look_direction(dx, dy);
                    if (look != pending_look) { pending_look = look; pending_look_since = now; }
                    int new_row = 9 + look / 8, new_column = look % 8;
                    if (now - pending_look_since >= 0.18 && (row != new_row || column != new_column)) {
                        row = new_row; column = new_column; dirty = true;
                    }
                } else {
                    pending_look = -1;
                    if (row >= 9) { row = 0; column = 0; dirty = true; next_frame = now + frame_delay(0, 0); }
                }
            }
            if (!looking && now >= next_frame) {
                int count = row == 0 ? 6 : COUNTS[row];
                bool looping = row == 0 || row == 1 || row == 2;
                int new_column = looping ? (column + 1) % count : std::min(column + 1, count - 1);
                if (new_column != column) { column = new_column; dirty = true; }
                next_frame = now + frame_delay(row, column);
            }
        }
        if (dirty && IsWindow(window)) paint();
    }
    LRESULT handle(UINT message, WPARAM wp, LPARAM lp) {
        switch (message) {
        case WM_TIMER: tick(); return 0;
        case IPC: command(int(wp)); return 1;
        case WM_MOUSEACTIVATE: return MA_NOACTIVATE;
        case WM_ERASEBKGND: return 1;
        case WM_PAINT: { PAINTSTRUCT ps; BeginPaint(window, &ps); EndPaint(window, &ps); return 0; }
        case WM_LBUTTONDOWN:
            roaming = false; dragging = true; moved = false; suppress_click = false;
            GetCursorPos(&drag_pointer); drag_origin = prefs.position; SetCapture(window); return 0;
        case WM_MOUSEMOVE:
            if (dragging) {
                POINT p; GetCursorPos(&p);
                int dx = p.x - drag_pointer.x, dy = p.y - drag_pointer.y;
                if (std::abs(dx) + std::abs(dy) > 5) moved = true;
                if (moved) set_position({drag_origin.x + dx, drag_origin.y + dy});
            }
            return 0;
        case WM_LBUTTONUP:
            if (dragging) {
                dragging = false; ReleaseCapture();
                if (moved) { save(); next_action = now_seconds() + 45; }
                else if (!suppress_click && !prefs.paused) action(3);
            }
            suppress_click = false; return 0;
        case WM_LBUTTONDBLCLK:
            suppress_click = true; dragging = false; ReleaseCapture();
            if (!prefs.paused) action(4);
            return 0;
        case WM_CAPTURECHANGED: dragging = false; return 0;
        case WM_CONTEXTMENU: { POINT p; GetCursorPos(&p); menu(p); return 0; }
        case WM_KEYDOWN: if (wp == VK_ESCAPE) DestroyWindow(window); return 0;
        case WM_DPICHANGED:
            dpi = HIWORD(wp); resize(prefs.size);
            set_position({reinterpret_cast<RECT*>(lp)->left, reinterpret_cast<RECT*>(lp)->top}); return 0;
        case WM_DISPLAYCHANGE: set_position(prefs.position); return 0;
        case WM_SETTINGCHANGE: if (wp == SPI_SETWORKAREA) set_position(prefs.position); return 0;
        case WM_QUERYENDSESSION: save(); return TRUE;
        case WM_CLOSE: DestroyWindow(window); return 0;
        case WM_DESTROY:
            KillTimer(window, 1);
            try { save(); } catch (...) { /* Exiting must remain possible if the settings folder is unavailable. */ }
            PostQuitMessage(failed ? 1 : 0); return 0;
        }
        return DefWindowProcW(window, message, wp, lp);
    }
    static LRESULT CALLBACK procedure(HWND hwnd, UINT message, WPARAM wp, LPARAM lp) {
        PetWindow* pet = reinterpret_cast<PetWindow*>(GetWindowLongPtrW(hwnd, GWLP_USERDATA));
        if (message == WM_NCCREATE) {
            pet = static_cast<PetWindow*>(reinterpret_cast<CREATESTRUCTW*>(lp)->lpCreateParams);
            pet->window = hwnd;
            SetWindowLongPtrW(hwnd, GWLP_USERDATA, reinterpret_cast<LONG_PTR>(pet));
        }
        if (!pet) return DefWindowProcW(hwnd, message, wp, lp);
        try { return pet->handle(message, wp, lp); }
        catch (const std::exception& error) {
            pet->failed = true;
            try { write_text(pet->data_dir + L"\\last-error.txt", error.what()); } catch (...) {}
            MessageBoxW(hwnd, widen(error.what()).c_str(), PET, MB_OK | MB_ICONERROR);
            DestroyWindow(hwnd); return 0;
        }
    }
    int run(const std::wstring& class_name) {
        HINSTANCE instance = GetModuleHandleW(nullptr);
        WNDCLASSEXW type = {};
        type.cbSize = sizeof(type); type.style = CS_DBLCLKS;
        type.lpfnWndProc = procedure; type.hInstance = instance;
        type.hCursor = LoadCursorW(nullptr, IDC_HAND);
        type.hIcon = LoadIconW(instance, MAKEINTRESOURCEW(1));
        type.hIconSm = type.hIcon; type.lpszClassName = class_name.c_str();
        require(RegisterClassExW(&type) != 0, "Could not register the pet window.");
        window = CreateWindowExW(WS_EX_LAYERED | WS_EX_TOOLWINDOW | WS_EX_NOACTIVATE |
            (prefs.topmost ? WS_EX_TOPMOST : 0), class_name.c_str(), (std::wstring(PET) + L" Offline").c_str(),
            WS_POPUP, 0, 0, width, height, nullptr, nullptr, instance, this);
        require(window != nullptr, "Could not create the pet window.");
        using GetDpi = UINT (WINAPI*)(HWND);
        auto get_dpi = reinterpret_cast<GetDpi>(GetProcAddress(GetModuleHandleW(L"user32.dll"), "GetDpiForWindow"));
        dpi = get_dpi ? int(get_dpi(window)) : 96;
        resize(prefs.size);
        if (prefs.position.x == LONG_MIN) home(); else set_position(prefs.position);
        next_action = now_seconds() + random(45, 90);
        paint(); ShowWindow(window, SW_SHOWNOACTIVATE);
        snapshot();
        require(SetTimer(window, 1, smoke ? 70 : 40, nullptr) != 0, "Could not start the animation timer.");
        MSG message;
        int result;
        while ((result = GetMessageW(&message, nullptr, 0, 0)) > 0) {
            TranslateMessage(&message); DispatchMessageW(&message);
        }
        return result < 0 ? 1 : int(message.wParam);
    }
};

static int self_test(Artwork& art, const std::wstring& report) {
    Surface surface;
    int frames = 0;
    for (int size : SIZES) {
        surface.resize(size, MulDiv(size, art.cell_height, art.cell_width));
        for (int row = 0; row < 11; ++row) for (int col = 0; col < COUNTS[row]; ++col) {
            surface.render(art, row, col);
            int occupied = 0, translucent = 0;
            for (int p = 0; p < surface.width * surface.height; ++p) {
                BYTE* pixel = surface.pixels + p * 4;
                occupied += pixel[3] > 32;
                translucent += pixel[3] > 0 && pixel[3] < 255;
                require(pixel[0] <= pixel[3] && pixel[1] <= pixel[3] && pixel[2] <= pixel[3],
                        "A frame is not premultiplied for Windows alpha blending.");
                int x = p % surface.width, y = p / surface.width;
                if (x < 2 || y < 2 || x >= surface.width - 2 || y >= surface.height - 2)
                    require(pixel[3] == 0, "A sprite touches its cell edge or contains a neighboring frame fragment.");
            }
            double coverage = double(occupied) / (surface.width * surface.height);
            Gdiplus::Color source_pixel;
            art.atlas->GetPixel(col * art.cell_width + art.cell_width / 2,
                                row * art.cell_height + art.cell_height / 2, &source_pixel);
            require(coverage > 0.08 && coverage < 0.95,
                ("Invalid alpha coverage " + std::to_string(coverage) + " at row " + std::to_string(row) +
                 ", column " + std::to_string(col) + ", size " + std::to_string(size) +
                 "; source alpha=" + std::to_string(source_pixel.GetA()) +
                 ", source cell=" + std::to_string(art.cell_width) + "x" + std::to_string(art.cell_height) + ".").c_str());
            require(translucent > 0, "An animation frame is missing smooth alpha edges.");
            ++frames;
        }
    }
    require(frames == 296, "Wrong animation frame count.");
    require(frame_delay(0, 0) >= 1.0 && frame_delay(1, 0) >= 0.20 &&
            action_duration(3) >= 2.0, "Quiet animation timing failed.");
    require(look_direction(0, -10) == 0 && look_direction(10, 0) == 4 &&
            look_direction(0, 10) == 8 && look_direction(-10, 0) == 12 &&
            look_direction(10, -10) == 2 && look_direction(-10, -10) == 14, "Cursor directions failed.");
    RECT area = {-1920, 0, 0, 1040};
    POINT p = clamp_point({-3000, 2000}, 192, 208, area);
    require(p.x == -1920 && p.y == 832, "Negative-monitor bounds failed.");
    p = clamp_point({900, -100}, 288, 312, {0, 0, 160, 120});
    require(p.x == 0 && p.y == 0, "Oversized-window bounds failed.");
    require(valid_size(192) && !valid_size(9000), "Size validation failed.");
    write_text(report, "PASS: all 74 embedded cells rendered at four sizes (296 frame checks).\n"
        "PASS: alpha coverage, premultiplied pixels, smooth edges and empty cell borders in every frame.\n"
        "PASS: cursor directions, negative-monitor bounds and oversized-window bounds.\n"
        "PASS: supported sizes and embedded atlas dimensions.\n");
    return 0;
}

int WINAPI wWinMain(HINSTANCE, HINSTANCE, PWSTR, int) {
    ULONG_PTR gdiplus_token = 0;
    HANDLE mutex = nullptr;
    std::wstring report;
    bool headless = false;
    int result = 1;
    try {
        int argc = 0;
        LPWSTR* argv = CommandLineToArgvW(GetCommandLineW(), &argc);
        require(argv != nullptr, "Could not read startup arguments.");
        std::wstring data = default_data_dir(), mode;
        int request = HOME;
        for (int i = 1; i < argc; ++i) {
            std::wstring arg = argv[i];
            if ((arg == L"--data-dir" || arg == L"--self-test" || arg == L"--smoke-test") && i + 1 < argc) {
                if (arg == L"--data-dir") data = argv[++i];
                else { mode = arg; report = argv[++i]; headless = mode == L"--self-test"; }
            } else if (arg == L"--exit") { mode = L"--request"; request = QUIT; }
            else if (arg == L"--snapshot") { mode = L"--request"; request = SNAPSHOT; }
            else if (arg == L"--command" && i + 1 < argc) { mode = L"--request"; request = _wtoi(argv[++i]); }
            else throw std::runtime_error("Unrecognized or incomplete startup argument.");
        }
        LocalFree(argv);
        if (mode == L"--smoke-test") data = report + L".state";
        std::wstring identity = std::wstring(L"DesktopPetLite2.") + PET + L"." + std::to_wstring(path_hash(data));
        if (mode == L"--request") {
            HWND existing = FindWindowW(identity.c_str(), nullptr);
            if (existing) {
                DWORD_PTR response = 0;
                require(SendMessageTimeoutW(existing, IPC, request, 0, SMTO_ABORTIFHUNG, 3000, &response),
                        "The running pet did not respond.");
            }
            return existing || request == QUIT ? 0 : 2;
        }
        if (mode != L"--self-test") {
            mutex = CreateMutexW(nullptr, FALSE, (L"Local\\" + identity).c_str());
            require(mutex != nullptr, "Could not create the pet instance lock.");
            if (GetLastError() == ERROR_ALREADY_EXISTS) {
                HWND existing = nullptr;
                for (int i = 0; i < 60 && !existing; ++i) { existing = FindWindowW(identity.c_str(), nullptr); if (!existing) Sleep(50); }
                require(existing != nullptr, "The pet is still starting. Please try again.");
                DWORD_PTR response = 0;
                require(SendMessageTimeoutW(existing, IPC, HOME, 0, SMTO_ABORTIFHUNG, 3000, &response),
                        "The running pet did not respond.");
                CloseHandle(mutex); return 0;
            }
            make_directory(data);
        }
        Gdiplus::GdiplusStartupInput input;
        require(Gdiplus::GdiplusStartup(&gdiplus_token, &input, nullptr) == Gdiplus::Ok,
                "Windows GDI+ could not start.");
        {
            Artwork art;
            if (headless) result = self_test(art, report);
            else {
                PetWindow pet(art, data);
                pet.smoke = mode == L"--smoke-test"; pet.smoke_report = report;
                result = pet.run(identity);
            }
        }
    } catch (const std::exception& error) {
        if (!report.empty()) { try { write_text(report, std::string("FAIL: ") + error.what()); } catch (...) {} }
        if (!headless) MessageBoxW(nullptr, widen(error.what()).c_str(), PET, MB_OK | MB_ICONERROR);
    }
    if (gdiplus_token) Gdiplus::GdiplusShutdown(gdiplus_token);
    if (mutex) CloseHandle(mutex);
    return result;
}
