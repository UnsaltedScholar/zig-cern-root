const std = @import("std");
const ArrayList = std.ArrayListUnmanaged;
const mem = std.mem;
const Allocator = mem.Allocator;
const FixedBufferAllocator = std.heap.FixedBufferAllocator;
const fs = std.fs;
const Build = std.Build;
const Module = Build.Module;
const CSourceLanguage = Module.CSourceLanguage;

const zcc = @import("compile_commands");

const additional_flags: []const []const u8 = &.{ "-std=c++17", "-pthread", "-m64" }; //, "-stdlib=libstdc++", "-rdynamic" };
const debug_flags = runtime_check_flags ++ warning_flags;

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});

    const optimize = b.standardOptimizeOption(.{});

    const exe = b.addExecutable(.{
        .name = "zig-compiled",
        .target = target,
        .optimize = optimize,
    });

    // Does not link asan or use build flags other than "std="
    const debug = b.addExecutable(.{
        .name = "debug",
        .target = target,
        .optimize = optimize,
    });

    const exe_flags = getBuildFlags(
        b.allocator,
        exe,
        optimize,
    ) catch |err|
        @panic(@errorName(err));

    const exe_files = getCSrcFiles(
        b.allocator,
        .{
            .dir_path = "src/cpp",
            .flags = exe_flags,
            .language = .cpp,
        },
    ) catch |err|
        @panic(@errorName(err));

    // Setup exe executable
    {
        exe.addCSourceFiles(exe_files);
        // exe.linkLibCpp(); // May need to change this to linkLibC() for your project
        // exe.linkSystemLibrary("stdc++");
        exe.linkSystemLibrary("c++");
        exe.addIncludePath(b.path("include"));
        // exe.addIncludePath(b.path("include/bits"));
        exe.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/" });
        exe.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/bits/" });
        exe.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/x86_64-pc-linux-gnu/" });
        exe.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/x86_64-pc-linux-gnu/bits/" });
        // exe.addIncludePath(std.Build.LazyPath{.cwd_relative = "/usr/include/ROOT/RDF/"});
        // exe.addIncludePath(std.Build.LazyPath{.cwd_relative = "/usr/include/ROOT/"});
        // exe.addIncludePath(std.Build.LazyPath{.cwd_relative = "/usr/include/Math/"});
    }

    // Setup debug executable
    {
        var debug_files = exe_files;
        debug_files.flags = additional_flags;
        debug.addCSourceFiles(debug_files);

        // debug.linkLibCpp(); // May need to change this to linkLibC() for your project
        // debug.linkSystemLibrary("stdc++");
        debug.linkSystemLibrary("c++");
        debug.addIncludePath(b.path("include"));
        // debug.addIncludePath(b.path("include/bits"));
        debug.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/" });
        debug.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/bits/" });
        debug.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/x86_64-pc-linux-gnu/" });
        debug.addIncludePath(std.Build.LazyPath{ .cwd_relative = "/usr/include/c++/15.1.1/x86_64-pc-linux-gnu/bits/" });
        // debug.addIncludePath(std.Build.LazyPath{.cwd_relative = "/usr/include/ROOT/RDF/"});
        // debug.addIncludePath(std.Build.LazyPath{.cwd_relative = "/usr/include/ROOT/"});
        // debug.addIncludePath(std.Build.LazyPath{.cwd_relative = "/usr/include/Math/"});
    }

    // Build and Link zig -> c code -------------------------------------------
    // const zig_lib = b.addStaticLibrary(.{
    //     .name = "mathtest",
    //     .root_source_file = b.path("src/zig/mathtest.zig"),
    //     .target = target,
    //     .optimize = optimize,
    // });
    // zig_lib.linkLibC();
    // zig_lib.addIncludePath(b.path("include/"));
    // exe.linkLibrary(zig_lib);
    // debug.linkLibrary(zig_lib);
    //-------------------------------------------------------------------------

    // Build and/or Link Dynamic library --------------------------------------
    const dynamic_option = b.option(bool, "build-dynamic", "builds the static.a file") orelse false;
    if (dynamic_option) {
        // const dynamic_lib = createDynamicLib(b, optimize, target);
        // exe.linkLibrary(dynamic_lib);
        // debug.linkLibrary(dynamic_lib);
        // b.installArtifact(dynamic_lib);
    } else {
        exe.addLibraryPath(std.Build.LazyPath{ .cwd_relative = "/usr/lib/root/" });
        exe.addLibraryPath(std.Build.LazyPath{ .cwd_relative = "/usr/lib/clang/" });
        // exe.linkSystemLibrary("Core");
        // exe.linkSystemLibrary("Imt");
        // exe.linkSystemLibrary("RIO");
        // exe.linkSystemLibrary("Net");
        // exe.linkSystemLibrary("Hist");
        // exe.linkSystemLibrary("Graf");
        // exe.linkSystemLibrary("Graf3d");
        // exe.linkSystemLibrary("Gpad");
        // exe.linkSystemLibrary("ROOTVecOps");
        // exe.linkSystemLibrary("Tree");
        // exe.linkSystemLibrary("TreePlayer");
        // exe.linkSystemLibrary("Rint");
        // exe.linkSystemLibrary("Postscript");
        // exe.linkSystemLibrary("Matrix");
        // exe.linkSystemLibrary("Physics");
        // exe.linkSystemLibrary("MathCore");
        // exe.linkSystemLibrary("Thread");
        // exe.linkSystemLibrary("ROOTNTuple");
        // exe.linkSystemLibrary("MultiProc");
        // exe.linkSystemLibrary("ROOTDataFrame");
        // exe.linkSystemLibrary("ROOTNTupleUtil");
        // exe.linkSystemLibrary("Minuit2");
        // exe.linkSystemLibrary("GenVector");
        exe.linkSystemLibrary("LLVM");
        exe.linkSystemLibrary("unwind");
        exe.linkSystemLibrary("Cling");
        exe.linkSystemLibrary("pthread");
        exe.linkSystemLibrary("m");
        exe.linkSystemLibrary("dl");
        exe.linkSystemLibrary("ASImageGui");
        exe.linkSystemLibrary("ASImage");
        exe.linkSystemLibrary("Cling");
        exe.linkSystemLibrary("complexDict");
        exe.linkSystemLibrary("Core");
        exe.linkSystemLibrary("cppyy_backend");
        exe.linkSystemLibrary("cppyy");
        exe.linkSystemLibrary("dequeDict");
        exe.linkSystemLibrary("EGPythia8");
        exe.linkSystemLibrary("EG");
        exe.linkSystemLibrary("Eve");
        exe.linkSystemLibrary("FFTW");
        exe.linkSystemLibrary("FitPanel");
        exe.linkSystemLibrary("FITSIO");
        exe.linkSystemLibrary("Foam");
        exe.linkSystemLibrary("forward_listDict");
        exe.linkSystemLibrary("Fumili");
        exe.linkSystemLibrary("Gdml");
        exe.linkSystemLibrary("Ged");
        exe.linkSystemLibrary("Genetic");
        exe.linkSystemLibrary("GenVector");
        exe.linkSystemLibrary("GeomPainter");
        exe.linkSystemLibrary("Geom");
        exe.linkSystemLibrary("Gpad");
        exe.linkSystemLibrary("Graf3d");
        exe.linkSystemLibrary("Graf");
        exe.linkSystemLibrary("GuiBld");
        exe.linkSystemLibrary("GuiHtml");
        exe.linkSystemLibrary("Gui");
        exe.linkSystemLibrary("Gviz3d");
        exe.linkSystemLibrary("Gviz");
        exe.linkSystemLibrary("GX11");
        exe.linkSystemLibrary("GX11TTF");
        exe.linkSystemLibrary("Hbook");
        exe.linkSystemLibrary("HistFactory");
        exe.linkSystemLibrary("HistPainter");
        exe.linkSystemLibrary("Hist");
        exe.linkSystemLibrary("Imt");
        exe.linkSystemLibrary("listDict");
        exe.linkSystemLibrary("map2Dict");
        exe.linkSystemLibrary("mapDict");
        exe.linkSystemLibrary("MathCore");
        exe.linkSystemLibrary("MathMore");
        exe.linkSystemLibrary("Matrix");
        exe.linkSystemLibrary("Minuit2");
        exe.linkSystemLibrary("Minuit");
        exe.linkSystemLibrary("MLP");
        exe.linkSystemLibrary("multimap2Dict");
        exe.linkSystemLibrary("multimapDict");
        exe.linkSystemLibrary("MultiProc");
        exe.linkSystemLibrary("multisetDict");
        exe.linkSystemLibrary("Net");
        exe.linkSystemLibrary("NetxNG");
        exe.linkSystemLibrary("New");
        exe.linkSystemLibrary("PgSQL");
        exe.linkSystemLibrary("Physics");
        exe.linkSystemLibrary("Postscript");
        exe.linkSystemLibrary("PyMVA");
        exe.linkSystemLibrary("Quadp");
        exe.linkSystemLibrary("RCsg");
        exe.linkSystemLibrary("Recorder");
        exe.linkSystemLibrary("RGL");
        exe.linkSystemLibrary("RHTTPSniff");
        exe.linkSystemLibrary("RHTTP");
        exe.linkSystemLibrary("Rint");
        exe.linkSystemLibrary("RIO");
        exe.linkSystemLibrary("RMPI");
        exe.linkSystemLibrary("RMySQL");
        exe.linkSystemLibrary("RODBC");
        exe.linkSystemLibrary("RooBatchCompute_AVX2");
        exe.linkSystemLibrary("RooBatchCompute_AVX512");
        exe.linkSystemLibrary("RooBatchCompute_AVX");
        exe.linkSystemLibrary("RooBatchCompute_CUDA");
        exe.linkSystemLibrary("RooBatchCompute_GENERIC");
        exe.linkSystemLibrary("RooBatchCompute");
        exe.linkSystemLibrary("RooBatchCompute_SSE4.1");
        exe.linkSystemLibrary("RooFitCodegen");
        exe.linkSystemLibrary("RooFitCore");
        exe.linkSystemLibrary("RooFitHS3");
        exe.linkSystemLibrary("RooFitJSONInterface");
        exe.linkSystemLibrary("RooFitMore");
        exe.linkSystemLibrary("RooFit");
        exe.linkSystemLibrary("RooFitXRooFit");
        exe.linkSystemLibrary("RooStats");
        exe.linkSystemLibrary("RootAuth");
        exe.linkSystemLibrary("ROOTBranchBrowseProvider");
        exe.linkSystemLibrary("ROOTBrowsable");
        exe.linkSystemLibrary("ROOTBrowserGeomWidget");
        exe.linkSystemLibrary("ROOTBrowserRCanvasWidget");
        exe.linkSystemLibrary("ROOTBrowserTCanvasWidget");
        exe.linkSystemLibrary("ROOTBrowserTreeWidget");
        exe.linkSystemLibrary("ROOTBrowserv7");
        exe.linkSystemLibrary("ROOTBrowserWidgets");
        exe.linkSystemLibrary("ROOTCanvasPainter");
        exe.linkSystemLibrary("ROOTDataFrame");
        exe.linkSystemLibrary("ROOTEve");
        exe.linkSystemLibrary("ROOTFitPanelv7");
        exe.linkSystemLibrary("ROOTGeoBrowseProvider");
        exe.linkSystemLibrary("ROOTGeomViewer");
        exe.linkSystemLibrary("ROOTGpadv7");
        exe.linkSystemLibrary("ROOTGraphicsPrimitives");
        exe.linkSystemLibrary("ROOTLeafDraw6Provider");
        exe.linkSystemLibrary("ROOTLeafDraw7Provider");
        exe.linkSystemLibrary("ROOTNTupleBrowseProvider");
        exe.linkSystemLibrary("ROOTNTupleDraw6Provider");
        exe.linkSystemLibrary("ROOTNTupleDraw7Provider");
        exe.linkSystemLibrary("ROOTNTuple");
        exe.linkSystemLibrary("ROOTNTupleUtil");
        exe.linkSystemLibrary("ROOTObjectDraw6Provider");
        exe.linkSystemLibrary("ROOTObjectDraw7Provider");
        exe.linkSystemLibrary("ROOTPythonizations");
        exe.linkSystemLibrary("ROOTQt6WebDisplay");
        exe.linkSystemLibrary("ROOTTMVASofie");
        exe.linkSystemLibrary("ROOTTPython");
        exe.linkSystemLibrary("ROOTTreeViewer");
        exe.linkSystemLibrary("ROOTVecOps");
        exe.linkSystemLibrary("ROOTWebDisplay");
        exe.linkSystemLibrary("RSQLite");
        exe.linkSystemLibrary("setDict");
        exe.linkSystemLibrary("Smatrix");
        exe.linkSystemLibrary("SpectrumPainter");
        exe.linkSystemLibrary("Spectrum");
        exe.linkSystemLibrary("SPlot");
        exe.linkSystemLibrary("SQLIO");
        exe.linkSystemLibrary("SrvAuth");
        exe.linkSystemLibrary("Thread");
        exe.linkSystemLibrary("TMVAGui");
        exe.linkSystemLibrary("TMVA");
        exe.linkSystemLibrary("TMVAUtils");
        exe.linkSystemLibrary("TreePlayer");
        exe.linkSystemLibrary("Tree");
        exe.linkSystemLibrary("TreeViewer");
        exe.linkSystemLibrary("unordered_mapDict");
        exe.linkSystemLibrary("unordered_multimapDict");
        exe.linkSystemLibrary("unordered_multisetDict");
        exe.linkSystemLibrary("unordered_setDict");
        exe.linkSystemLibrary("Unuran");
        exe.linkSystemLibrary("valarrayDict");
        exe.linkSystemLibrary("vectorDict");
        exe.linkSystemLibrary("WebGui6");
        exe.linkSystemLibrary("X3d");
        exe.linkSystemLibrary("XMLIO");
        exe.linkSystemLibrary("XMLParser");
        debug.addLibraryPath(std.Build.LazyPath{ .cwd_relative = "/usr/lib/root/" });
        debug.addLibraryPath(std.Build.LazyPath{ .cwd_relative = "/usr/lib/clang/" });
        // debug.linkSystemLibrary("Core");
        // debug.linkSystemLibrary("Imt");
        // debug.linkSystemLibrary("RIO");
        // debug.linkSystemLibrary("Net");
        // debug.linkSystemLibrary("Hist");
        // debug.linkSystemLibrary("Graf");
        // debug.linkSystemLibrary("Graf3d");
        // debug.linkSystemLibrary("Gpad");
        // debug.linkSystemLibrary("ROOTVecOps");
        // debug.linkSystemLibrary("Tree");
        // debug.linkSystemLibrary("TreePlayer");
        // debug.linkSystemLibrary("Rint");
        // debug.linkSystemLibrary("Postscript");
        // debug.linkSystemLibrary("Matrix");
        // debug.linkSystemLibrary("Physics");
        // debug.linkSystemLibrary("MathCore");
        // debug.linkSystemLibrary("Thread");
        // debug.linkSystemLibrary("ROOTNTuple");
        // debug.linkSystemLibrary("MultiProc");
        // debug.linkSystemLibrary("ROOTDataFrame");
        // debug.linkSystemLibrary("ROOTNTupleUtil");
        // debug.linkSystemLibrary("Minuit2");
        // debug.linkSystemLibrary("GenVector");
        debug.linkSystemLibrary("LLVM");
        debug.linkSystemLibrary("unwind");
        debug.linkSystemLibrary("Cling");
        debug.linkSystemLibrary("pthread");
        debug.linkSystemLibrary("m");
        debug.linkSystemLibrary("dl");
        debug.linkSystemLibrary("ASImageGui");
        debug.linkSystemLibrary("ASImage");
        debug.linkSystemLibrary("Cling");
        debug.linkSystemLibrary("complexDict");
        debug.linkSystemLibrary("Core");
        debug.linkSystemLibrary("cppyy_backend");
        debug.linkSystemLibrary("cppyy");
        debug.linkSystemLibrary("dequeDict");
        debug.linkSystemLibrary("EGPythia8");
        debug.linkSystemLibrary("EG");
        debug.linkSystemLibrary("Eve");
        debug.linkSystemLibrary("FFTW");
        debug.linkSystemLibrary("FitPanel");
        debug.linkSystemLibrary("FITSIO");
        debug.linkSystemLibrary("Foam");
        debug.linkSystemLibrary("forward_listDict");
        debug.linkSystemLibrary("Fumili");
        debug.linkSystemLibrary("Gdml");
        debug.linkSystemLibrary("Ged");
        debug.linkSystemLibrary("Genetic");
        debug.linkSystemLibrary("GenVector");
        debug.linkSystemLibrary("GeomPainter");
        debug.linkSystemLibrary("Geom");
        debug.linkSystemLibrary("Gpad");
        debug.linkSystemLibrary("Graf3d");
        debug.linkSystemLibrary("Graf");
        debug.linkSystemLibrary("GuiBld");
        debug.linkSystemLibrary("GuiHtml");
        debug.linkSystemLibrary("Gui");
        debug.linkSystemLibrary("Gviz3d");
        debug.linkSystemLibrary("Gviz");
        debug.linkSystemLibrary("GX11");
        debug.linkSystemLibrary("GX11TTF");
        debug.linkSystemLibrary("Hbook");
        debug.linkSystemLibrary("HistFactory");
        debug.linkSystemLibrary("HistPainter");
        debug.linkSystemLibrary("Hist");
        debug.linkSystemLibrary("Imt");
        debug.linkSystemLibrary("listDict");
        debug.linkSystemLibrary("map2Dict");
        debug.linkSystemLibrary("mapDict");
        debug.linkSystemLibrary("MathCore");
        debug.linkSystemLibrary("MathMore");
        debug.linkSystemLibrary("Matrix");
        debug.linkSystemLibrary("Minuit2");
        debug.linkSystemLibrary("Minuit");
        debug.linkSystemLibrary("MLP");
        debug.linkSystemLibrary("multimap2Dict");
        debug.linkSystemLibrary("multimapDict");
        debug.linkSystemLibrary("MultiProc");
        debug.linkSystemLibrary("multisetDict");
        debug.linkSystemLibrary("Net");
        debug.linkSystemLibrary("NetxNG");
        debug.linkSystemLibrary("New");
        debug.linkSystemLibrary("PgSQL");
        debug.linkSystemLibrary("Physics");
        debug.linkSystemLibrary("Postscript");
        debug.linkSystemLibrary("PyMVA");
        debug.linkSystemLibrary("Quadp");
        debug.linkSystemLibrary("RCsg");
        debug.linkSystemLibrary("Recorder");
        debug.linkSystemLibrary("RGL");
        debug.linkSystemLibrary("RHTTPSniff");
        debug.linkSystemLibrary("RHTTP");
        debug.linkSystemLibrary("Rint");
        debug.linkSystemLibrary("RIO");
        debug.linkSystemLibrary("RMPI");
        debug.linkSystemLibrary("RMySQL");
        debug.linkSystemLibrary("RODBC");
        debug.linkSystemLibrary("RooBatchCompute_AVX2");
        debug.linkSystemLibrary("RooBatchCompute_AVX512");
        debug.linkSystemLibrary("RooBatchCompute_AVX");
        debug.linkSystemLibrary("RooBatchCompute_CUDA");
        debug.linkSystemLibrary("RooBatchCompute_GENERIC");
        debug.linkSystemLibrary("RooBatchCompute");
        debug.linkSystemLibrary("RooBatchCompute_SSE4.1");
        debug.linkSystemLibrary("RooFitCodegen");
        debug.linkSystemLibrary("RooFitCore");
        debug.linkSystemLibrary("RooFitHS3");
        debug.linkSystemLibrary("RooFitJSONInterface");
        debug.linkSystemLibrary("RooFitMore");
        debug.linkSystemLibrary("RooFit");
        debug.linkSystemLibrary("RooFitXRooFit");
        debug.linkSystemLibrary("RooStats");
        debug.linkSystemLibrary("RootAuth");
        debug.linkSystemLibrary("ROOTBranchBrowseProvider");
        debug.linkSystemLibrary("ROOTBrowsable");
        debug.linkSystemLibrary("ROOTBrowserGeomWidget");
        debug.linkSystemLibrary("ROOTBrowserRCanvasWidget");
        debug.linkSystemLibrary("ROOTBrowserTCanvasWidget");
        debug.linkSystemLibrary("ROOTBrowserTreeWidget");
        debug.linkSystemLibrary("ROOTBrowserv7");
        debug.linkSystemLibrary("ROOTBrowserWidgets");
        debug.linkSystemLibrary("ROOTCanvasPainter");
        debug.linkSystemLibrary("ROOTDataFrame");
        debug.linkSystemLibrary("ROOTEve");
        debug.linkSystemLibrary("ROOTFitPanelv7");
        debug.linkSystemLibrary("ROOTGeoBrowseProvider");
        debug.linkSystemLibrary("ROOTGeomViewer");
        debug.linkSystemLibrary("ROOTGpadv7");
        debug.linkSystemLibrary("ROOTGraphicsPrimitives");
        debug.linkSystemLibrary("ROOTLeafDraw6Provider");
        debug.linkSystemLibrary("ROOTLeafDraw7Provider");
        debug.linkSystemLibrary("ROOTNTupleBrowseProvider");
        debug.linkSystemLibrary("ROOTNTupleDraw6Provider");
        debug.linkSystemLibrary("ROOTNTupleDraw7Provider");
        debug.linkSystemLibrary("ROOTNTuple");
        debug.linkSystemLibrary("ROOTNTupleUtil");
        debug.linkSystemLibrary("ROOTObjectDraw6Provider");
        debug.linkSystemLibrary("ROOTObjectDraw7Provider");
        debug.linkSystemLibrary("ROOTPythonizations");
        debug.linkSystemLibrary("ROOTQt6WebDisplay");
        debug.linkSystemLibrary("ROOTTMVASofie");
        debug.linkSystemLibrary("ROOTTPython");
        debug.linkSystemLibrary("ROOTTreeViewer");
        debug.linkSystemLibrary("ROOTVecOps");
        debug.linkSystemLibrary("ROOTWebDisplay");
        debug.linkSystemLibrary("RSQLite");
        debug.linkSystemLibrary("setDict");
        debug.linkSystemLibrary("Smatrix");
        debug.linkSystemLibrary("SpectrumPainter");
        debug.linkSystemLibrary("Spectrum");
        debug.linkSystemLibrary("SPlot");
        debug.linkSystemLibrary("SQLIO");
        debug.linkSystemLibrary("SrvAuth");
        debug.linkSystemLibrary("Thread");
        debug.linkSystemLibrary("TMVAGui");
        debug.linkSystemLibrary("TMVA");
        debug.linkSystemLibrary("TMVAUtils");
        debug.linkSystemLibrary("TreePlayer");
        debug.linkSystemLibrary("Tree");
        debug.linkSystemLibrary("TreeViewer");
        debug.linkSystemLibrary("unordered_mapDict");
        debug.linkSystemLibrary("unordered_multimapDict");
        debug.linkSystemLibrary("unordered_multisetDict");
        debug.linkSystemLibrary("unordered_setDict");
        debug.linkSystemLibrary("Unuran");
        debug.linkSystemLibrary("valarrayDict");
        debug.linkSystemLibrary("vectorDict");
        debug.linkSystemLibrary("WebGui6");
        debug.linkSystemLibrary("X3d");
        debug.linkSystemLibrary("XMLIO");
        debug.linkSystemLibrary("XMLParser");
    }
    //-------------------------------------------------------------------------

    // Build and/or Link Static library --------------------------------------
    const static_option = b.option(bool, "build-static", "builds the static.a file") orelse false;
    if (static_option) {
        // const static_lib = createStaticLib(b, optimize, target);
        // exe.linkLibrary(static_lib);
        // debug.linkLibrary(static_lib);
        // zig_lib.linkLibrary(static_lib);
        // b.installArtifact(static_lib);
    } else {
        //     exe.addLibraryPath(b.path("lib/"));
        //     exe.linkSystemLibrary("example_static");
        //     debug.addLibraryPath(b.path("lib/"));
        //     debug.linkSystemLibrary("example_static");
    }
    //-------------------------------------------------------------------------

    b.installArtifact(exe);
    const exe_run = b.addRunArtifact(exe);
    const debug_run = b.addRunArtifact(debug);

    exe_run.step.dependOn(b.getInstallStep());

    if (b.args) |args| {
        exe_run.addArgs(args);
        debug_run.addArgs(args);
    }

    const run_step = b.step("run", "runs the application");
    run_step.dependOn(&exe_run.step);

    const debug_step = b.step("debug", "runs the applicaiton without any warning or san flags");

    // Causes debug to only be compiled when using debug step.
    debug_step.dependOn(&b.addInstallArtifact(debug, .{}).step);

    var targets = ArrayList(*std.Build.Step.Compile).empty;
    defer targets.deinit(b.allocator);

    targets.append(b.allocator, exe) catch |err| @panic(@errorName(err));
    targets.append(b.allocator, debug) catch |err| @panic(@errorName(err));

    // Used to generate compile_commands.json
    _ = zcc.createStep(
        b,
        "cmds",
        targets.toOwnedSlice(b.allocator) catch |err|
            @panic(@errorName(err)),
    );
}

/// Used to recursively fetch source files from a directory
pub fn getCSrcFiles(
    alloc: std.mem.Allocator,
    opts: struct {
        dir_path: []const u8 = "./src/",
        language: CSourceLanguage,
        flags: []const []const u8 = &.{},
    },
) !Module.AddCSourceFilesOptions {
    const src = try fs.cwd().openDir(opts.dir_path, .{ .iterate = true });

    var file_list = ArrayList([]const u8).empty;
    errdefer file_list.deinit(alloc);

    const extension = @tagName(opts.language); // Will break for obj-c and assembly

    var src_iterator = src.iterate();
    while (try src_iterator.next()) |entry| {
        switch (entry.kind) {
            .file => {
                if (!mem.endsWith(u8, entry.name, extension))
                    continue;

                const path = try fs.path.join(alloc, &.{ opts.dir_path, entry.name });

                try file_list.append(alloc, path);
            },
            .directory => {
                var dir_opts = opts;
                dir_opts.dir_path = try fs.path.join(alloc, &.{ opts.dir_path, entry.name });

                try file_list.appendSlice(alloc, (try getCSrcFiles(alloc, dir_opts)).files);
            },
            else => continue,
        }
    }

    return Module.AddCSourceFilesOptions{
        .files = try file_list.toOwnedSlice(alloc),
        .language = opts.language,
        .flags = opts.flags,
    };
}

/// Returns the path of the system installation of clang sanitizers
fn getClangPath(alloc: std.mem.Allocator, target: std.Target) ![]const u8 {
    const asan_lib = if (target.os.tag == .windows) "clang_rt.asan_dynamic-x86_64.dll" else "libclang_rt.asan-x86_64.so";
    var child_proc = std.process.Child.init(&.{
        "clang",
        try std.mem.concat(alloc, u8, &.{ "-print-file-name=", asan_lib }),
    }, alloc);
    child_proc.stdout_behavior = .Pipe;

    try child_proc.spawn();

    const child_std_out = child_proc.stdout.?;

    var output = try child_std_out.reader().readAllAlloc(alloc, 512);

    _ = try child_proc.wait();

    const file_delim = if (target.os.tag == .windows) "\\" else "/";

    if (mem.lastIndexOf(u8, output, file_delim)) |last_path_sep| {
        output.len = last_path_sep + 1;
    } else {
        @panic("Path Not Formatted Correctly");
    }
    return output;
}

const runtime_check_flags: []const []const u8 = &.{
    "-fsanitize=array-bounds,null,alignment,unreachable,address,leak", // asan and leak are linux/macos only in 0.14.1
    "-fstack-protector-strong",
    "-fno-omit-frame-pointer",
};

const warning_flags: []const []const u8 = &.{
    "-Wall",
    "-Wextra",
    "-Wnull-dereference",
    "-Wuninitialized",
    "-Wshadow",
    "-Wpointer-arith",
    "-Wstrict-aliasing",
    "-Wstrict-overflow=5",
    "-Wcast-align",
    "-Wconversion",
    "-Wsign-conversion",
    "-Wfloat-equal",
    "-Wformat=2",
    "-Wswitch-enum",
    "-Wmissing-declarations",
    "-Wunused",
    "-Wundef",
    "-Werror",
};

/// Returns the build flags used depending on optimization level.
/// Will automatically link asan to exe if debug mode is used.
fn getBuildFlags(
    alloc: Allocator,
    exe: *std.Build.Step.Compile,
    optimize: std.builtin.OptimizeMode,
) ![]const []const u8 {
    var cpp_flags: []const []const u8 = undefined;

    if (optimize == .Debug) {
        cpp_flags = additional_flags ++ debug_flags;
        if (exe.rootModuleTarget().os.tag == .windows)
            return cpp_flags;

        exe.addLibraryPath(.{ .cwd_relative = try getClangPath(alloc, exe.rootModuleTarget()) });
        const asan_lib = if (exe.rootModuleTarget().os.tag == .windows) "clang_rt.asan_dynamic-x86_64" // Won't be triggered in current version
            else "clang_rt.asan-x86_64";

        exe.linkSystemLibrary(asan_lib);
    } else {
        cpp_flags = additional_flags;
    }
    return cpp_flags;
}

// / Creates the example dynamic library. Not required if not using project example libaries
// fn createDynamicLib(
//     b: *Build,
//     optimize: std.builtin.OptimizeMode,
//     target: Build.ResolvedTarget,
// ) *Build.Step.Compile {
//     var dynamic_lib = b.addSharedLibrary(.{
//         .name = "example_dynamic",
//         .optimize = optimize,
//         .target = target,
//     });
//
//     dynamic_lib.addCSourceFiles(
//         getCSrcFiles(
//             b.allocator,
//             .{
//                 .dir_path = "./lib/example-dynamic-lib/",
//                 .language = .cpp,
//             },
//         ) catch |err|
//             @panic(@errorName(err)),
//     );
//
//     dynamic_lib.addIncludePath(b.path("include/"));
//     dynamic_lib.linkLibCpp();
//     return dynamic_lib;
// }

// / Creates the example static library. Not required if not using project example libaries
// fn createStaticLib(
//     b: *Build,
//     optimize: std.builtin.OptimizeMode,
//     target: Build.ResolvedTarget,
// ) *Build.Step.Compile {
//     var dynamic_lib = b.addStaticLibrary(.{
//         .name = "example_static",
//         .optimize = optimize,
//         .target = target,
//     });
//
//     dynamic_lib.addCSourceFiles(
//         getCSrcFiles(b.allocator, .{
//             .dir_path = "./lib/example-static-lib/",
//             .language = .c,
//         }) catch |err|
//             @panic(@errorName(err)),
//     );
//
//     dynamic_lib.addIncludePath(b.path("include/"));
//     dynamic_lib.linkLibC();
//     return dynamic_lib;
// }
