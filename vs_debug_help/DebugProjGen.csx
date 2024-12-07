using System;
using System.Text.RegularExpressions;
using System.IO;


void Main(){
	var opts = new Opts();
	var usage = @"
	csi DebugProjGen.csx --exe ln --include_paths './'

		You can run it from the root project folder (probably easiest) or script folder as long as proj_config.ini is in the same folder.  You need a proj_config.ini to generate run '/script/f_coreutils_build.sh export_config' to generate this.
		The paths and project files will be generated relative to the project root.  for include/compile files if they don't exist relative to the root dir but do in one of the include paths it will use that path.
		
		
		For array args you can specify multiple separated by spaces until the next arg
		--exe [name] - name of output executable, ie find
		Array Args:
		--include_paths - additional paths to include
		--library_paths - additonal paths for library search
		--libaries - additional libraries to include
		--ALT_DEBUG_HEADER_DIR - define a subdir for the debug.h header to be placed in if not the root dir
		--compile - additional files to add for compiling, if you just copy from DEBUG_GNU_COMPILE_WRAPPER=1  it will replace .obj with .c by default
		--replace_ext [cpp] - replace with what extension if not .c
		--include - additional files to include (ie .h)
		--exclude - files to not include in includes or compile (incase of wildcard usage)
		--define - additional defines to make (may want to single quote kvp with StringSplitOptions
		--no_autoheader - don't add the .h file for each compile file if it is found and exists
		--debug_cpp - write debug file as .cpp rather than .c

	";
	if (String.IsNullOrWhiteSpace(opts.GetVal("exe"))) {
		Console.Error.WriteLine(usage);
		Environment.Exit(1);
	}
	var config = new ConfigRead();
	config.ReadConfig();
	var VS_DEBUG_FOLDER = Path.Combine(config.GetVal("SCRIPT_FOLDER"), "vs_debug_help");
	var TEMPLATE_DICT = BuildTemplateDict(config, opts);
	DoFileReplace("ProjTemplate.sln", config, TEMPLATE_DICT, "[PROJ_NAME].sln");
	DoFileReplace("ProjTemplate.vcxproj", config, TEMPLATE_DICT, "[PROJ_NAME].vcxproj");
	DoFileReplace("ProjTemplate.vcxproj.filters", config, TEMPLATE_DICT, "[PROJ_NAME].vcxproj.filters");
	var ROOT_DIR = config.GetVal("SRC_FOLDER");
	var ALT_DEBUG_HEADER_DIR = opts.GetVal("ALT_DEBUG_HEADER_DIR");
	var copy = new[] { "wlb_debug.c", "wlb_debug.h", "osfixes.h", "osfixes.c" };
	foreach (var fl in copy) {
		var useSymlink = false;
		var dstName = fl;
		if (fl == "wlb_debug.c" || fl =="osfixes.c" || fl=="osfixes.h"){
			useSymlink=true;
			 if(opts.GetValBool("debug_cpp") && fl.EndsWith(".c"))
				dstName = fl+"pp";
		}
		var dir = ROOT_DIR;
		if ((fl == "wlb_debug.h" || fl == "osfixes.h") && String.IsNullOrWhiteSpace(ALT_DEBUG_HEADER_DIR) == false)
			dir = Path.Combine(dir,ALT_DEBUG_HEADER_DIR);		
		var target = Path.Combine(dir, dstName);
		if (! File.Exists(target)){
			var src_path = Path.Combine(config.GetVal("SCRIPT_FOLDER"),fl);
			if (! File.Exists(src_path))
				src_path=Path.Combine(VS_DEBUG_FOLDER, fl);
			if (useSymlink)
				File.CreateSymbolicLink(target,src_path);
			else
				File.Copy(src_path, target, true);
		}
	}

	Console.WriteLine("DONE");

}
Main();
void TemplateReplace(ref string str, string name, string val) {
	str = str.Replace($"[{name}]", val);
}
void ArrPathFixForFiles(List<string> incl_paths, List<string> arr) {
	for (var x = 0; x < arr.Count; x++) {
		var fn = arr[x];
		if (!File.Exists(fn)) {
			var pathWFile = incl_paths.FirstOrDefault(a => File.Exists(Path.Combine(a, fn)));
			if (pathWFile != null)
				fn = Path.Combine(pathWFile, fn);
		}
		arr[x] = fn.Replace("\\", "/");
	}
}
void ArrExpandWithDefs(string root, List<string> arr, IEnumerable<string> addl, bool strip_path = false) {
	arr.AddRange(addl.Where(a => File.Exists(Path.Combine(root, a)) || Directory.Exists(Path.Combine(root, a))).Select(a => strip_path ? Path.GetFileName(a) : a));
	var l2 = arr.Distinct().ToList();
	arr.Clear();
	arr.AddRange(l2);
	//Console.WriteLine(string.Join(", ",arr));
	//throw new Exception("ERR");
}
void ArrExpandWildcards(string root, List<string> arr){
		for (var x = 0; x < arr.Count; x++){
		if (arr[x].Contains("*")){ //try to expand wildcards
			var dir = Path.GetDirectoryName(arr[x]);
			var file = Path.GetFileName(arr[x]);
			var all = Directory.GetFiles(Path.Combine(root,dir),file);
			arr.RemoveAt(x);
			foreach (var f in all){
				arr.Insert(x,f);
				x++;
			}
			x--;
		}
	}
}
void RelativePaths(string root, List<string> arr) {
	for (var x = 0; x < arr.Count; x++)
		arr[x] = Path.GetRelativePath(root.Replace("/","\\"),arr[x].Replace("/","\\")).Replace("\\","/");
}
Dictionary<string,string> BuildTemplateDict(ConfigRead config, Opts opts){
	var dict = new Dictionary<string,string>();
	void SetTemplateVal(String name, String val) => dict[name] = val;
	var ROOT_DIR = config.GetVal("SRC_FOLDER").Replace("\\","/");
	var lib_paths = opts.GetArrVal("library_paths");
	var incl_paths = opts.GetArrVal("include_paths");
	var libs = opts.GetArrVal("libraries");
	var compile = opts.GetArrVal("compile");
	var define = opts.GetArrVal("define");
	define = define.Select(a=>a.StartsWith("-D") ? a.Substring(2) : a).ToList();
	var include = opts.GetArrVal("include");
	var exclude = opts.GetArrVal("exclude");
	ArrExpandWildcards(ROOT_DIR,compile);
	ArrExpandWildcards(ROOT_DIR,include);
	compile = compile.Where(a=>exclude.Any(ex=> a.EndsWith(ex,StringComparison.CurrentCultureIgnoreCase)) == false).ToList();
	include = include.Where(a=>exclude.Any(ex=> a.EndsWith(ex,StringComparison.CurrentCultureIgnoreCase)) == false).ToList();
	ArrExpandWithDefs(ROOT_DIR, lib_paths, new[] { "", "lib", "gl/lib", "src", "gnu" });
	ArrExpandWithDefs(ROOT_DIR, incl_paths, new[] { "", "lib", "gl/lib", "gnu" });
	var replaceExt = opts.GetVal("replace_ext");
	if (String.IsNullOrWhiteSpace(replaceExt))
		replaceExt = "c";
	compile = compile.Select(a => a.EndsWith(".obj") ? a.Substring(0, a.Length - 3) + replaceExt : a).Distinct().ToList();
	ArrPathFixForFiles(incl_paths, compile);
	ArrPathFixForFiles(incl_paths, include);
	 if (! opts.GetValBool("no_autoheader")){
		var posHeaders = compile.Select(file => new FileInfo(file)).Select(fInfo => Path.Combine( fInfo.DirectoryName,fInfo.Name.Substring(0,fInfo.Name.Length-(fInfo.Extension.Length > 0 ? fInfo.Extension.Length+1 : 0)) + "h").Replace("\\","/")).ToList();
		ArrPathFixForFiles(incl_paths,posHeaders);
		var exists = posHeaders.Where(a=>File.Exists(a)).ToArray();
		include.AddRange(exists);
		foreach (var itm in exists)
			posHeaders.Remove(itm);
		posHeaders = posHeaders.Select(a=>new FileInfo(a).Name).ToList();
		ArrPathFixForFiles(incl_paths,posHeaders);
		exists = posHeaders.Where(a=>File.Exists(a)).ToArray();
		include.AddRange(exists);
    	    
	}

	ArrExpandWithDefs(ROOT_DIR, include, new[] { "config.h", "lib/config.h", $"{opts.GetVal("exe")}/defs.h", "lib/fcntl.h" });
	var chk_addl_libs = new List<string>(new[] { "src/libver.a", $"src/lib{config.GetVal("BUILD_NAME")}.a", $"lib/lib{config.GetVal("BUILD_NAME")}.a", $"lib/lib{config.GetVal("BUILD_NAME").Replace("utils", "")}.a", $"src/{config.GetVal("BUILD_NAME")}.a" });
	//lib/libcoreutils.a
	if (config.GetTrue("GNU_LIBS_USED")) {
		chk_addl_libs.AddRange(new[] { "gl/lib/libgnulib.a", "gnu/libgnu.a", "lib/libgnu.a" });
		define.Add("HAVE_CONFIG_H");
	}

	if (config.GetTrue("ADD_WIN_ARGV_LIB"))
		libs.Add("setargv.obj");
	libs.Add("legacy_stdio_definitions.lib");

	ArrExpandWithDefs(ROOT_DIR, libs, chk_addl_libs, true);
	compile.Add(opts.GetValBool("debug_cpp") ? "wlb_debug.cpp" : "wlb_debug.c");
	compile.Add(opts.GetValBool("debug_cpp") ? "osfixes.cpp" : "osfixes.c");
	include.Add("wlb_debug.h");
	include.Add("osfixes.h");
	
	RelativePaths(ROOT_DIR, compile);
	RelativePaths(ROOT_DIR, include);
	include = include.Distinct().ToList();
	compile = compile.Distinct().ToList();
	var all_files = new List<ProjFile>();
	all_files.AddRange(compile.Select(a=>new ProjFile(true,a)));
	all_files.AddRange(include.Select(a=>new ProjFile(false,a)));	
	
	SetTemplateVal("BIN_NAME", opts.GetVal("exe"));
	SetTemplateVal("PROJ_NAME", config.GetVal("BUILD_NAME"));
	SetTemplateVal("ADDL_LIBS", String.Join(";", libs));
	SetTemplateVal("INCLUDE_PATHS", String.Join(";", incl_paths));
	SetTemplateVal("LIB_PATHS", String.Join(";", lib_paths));
	SetTemplateVal("INCLUDE_FILES", String.Join("\n", all_files.Where(a=>a.compile==false).Select(a => a.ItemAsProj)));
	SetTemplateVal("COMPILE_FILES", String.Join("\n", all_files.Where(a=>a.compile).Select(a => a.ItemAsProj)));
	
	SetTemplateVal("INCLUDE_FILES_FILT", String.Join("\n", all_files.Where(a=>a.compile==false).Select(a => a.ItemAsProjFilter)));
	SetTemplateVal("COMPILE_FILES_FILT", String.Join("\n", all_files.Where(a=>a.compile).Select(a => a.ItemAsProjFilter)));

	//here we are building all distinct paths including parents to generate our folder structure
	var all_paths = new List<string>();
	all_paths.AddRange(all_files.Select(a=>a.ItemProjFilterFolderPath).Distinct());
	var tmp = all_paths;
	all_paths = all_paths.Select(a=>System.IO.Path.GetDirectoryName(a)).ToList();
	all_paths.AddRange(tmp);

	all_paths = all_paths.Select(a=>System.IO.Path.GetDirectoryName(a)).ToList();
	all_paths.AddRange(tmp);
	all_paths = all_paths.Where(a=>String.IsNullOrWhiteSpace(a) ==false).Distinct().ToList();
	
	SetTemplateVal("PROJ_FOLDERS_FILT", String.Join("\n",  all_paths.OrderBy(a=>a.Length).Select(a=>$@"<Filter Include=""{a}"">
	  <UniqueIdentifier>{Guid.NewGuid().ToString().ToLower()}</UniqueIdentifier>
</Filter>")  ));
	SetTemplateVal("DEFINES", String.Join(";", define.Distinct()));
	return dict;
}
void DoFileReplace(String filename, ConfigRead config, Dictionary<string,string> TEMPLATE_DICT, String save_filename) {
	var TEMPLATE_FOLDER = Path.Combine(config.GetVal("SCRIPT_FOLDER"), "vs_debug_help");
	var ROOT_DIR = config.GetVal("SRC_FOLDER").Replace("\\","/");
	filename = Path.Combine(TEMPLATE_FOLDER, filename);
	var text = File.ReadAllText(filename);
	TemplateReplace(ref save_filename, "PROJ_NAME", config.GetVal("BUILD_NAME"));

	Console.WriteLine($"ROOT: {ROOT_DIR} save file: {save_filename}");
	save_filename = Path.Combine(ROOT_DIR, save_filename);

	foreach (var kvp in TEMPLATE_DICT.OrderByDescending(a=>a.Key.Length)){
		TemplateReplace(ref text, kvp.Key, kvp.Value);
	}

	text = new Regex(@"[;]{2,}").Replace(text, ";");
	File.WriteAllText(save_filename, text);
}


class ProjFile{
	public bool compile;
	public string relative_folder;
	public string ItemProjFilterFolderPath => $"{(compile ? "Source" : "Header")} Files{(String.IsNullOrWhiteSpace(relative_folder) ? "" : $"\\{relative_folder}")}";
	public string ItemAsProj => @$"<Cl{(compile ? "Compile":"Include")} Include=""{relative_full_path}"" />";
	public string ItemAsProjFilter => @$"<Cl{(compile ? "Compile":"Include")} Include=""{relative_full_path}"">
	<Filter>{ItemProjFilterFolderPath}</Filter>
</Cl{(compile ? "Compile":"Include")}>";
	public string relative_full_path => Path.Combine(relative_folder,filename).Replace("/","\\");
	public string filename;
	public ProjFile(bool compile, String path){
		this.compile = compile;
		relative_folder = System.IO.Path.GetDirectoryName(path);
		filename = System.IO.Path.GetFileName(path);
	}
}
class ConfigRead {
	Dictionary<string, string> items = new();
	public void ReadConfig() {
		var PROJ_file = "proj_config.ini";
		if (!File.Exists(PROJ_file))
			throw new Exception($"Unable to find {PROJ_file} in current directory run /script/f_SCRIPTNAME_build.sh export_config to generate");
		var lines = File.ReadAllLines(PROJ_file);
		foreach (var line in lines) {
			if (!line.Contains("="))
				continue;
			var arr = line.Split(new[] { "=" }, 2, StringSplitOptions.None);
			var val = arr[1].Trim();
			if (val.StartsWith("\"") && val.EndsWith("\""))
				val = val.Substring(1, val.Length - 2);
			items[arr[0].Trim()] = val;
		}
	}
	public bool GetTrue(String name) {
		var val = GetVal(name);
		return (!String.IsNullOrWhiteSpace(val) && (val == "true" || val == "1"));
	}
	public string GetVal(String name) => items.TryGetValue(name, out var ret) ? ret : null;
}

class Opts {
	public string GetVal(String name) {
		var args = Environment.GetCommandLineArgs();
		var pos = Array.IndexOf(args, "--" + name);
		if (pos == -1)
			return null;
		return args[pos + 1];
	}
	public bool GetValBool(String name) {
		var args = Environment.GetCommandLineArgs();
		return Array.IndexOf(args, "--" + name) != -1;
	}
	public List<string> GetArrVal(String name) {
		var ret = new List<string>();
		var including = false;
		foreach (var arg in Environment.GetCommandLineArgs()) {
			if (arg.StartsWith("--")) {
				including = arg.Substring(2).Equals(name, StringComparison.CurrentCultureIgnoreCase);
				continue;
			}
			if (including)
				ret.Add(arg);
		}
		return ret.Distinct().ToList();
	}
}
