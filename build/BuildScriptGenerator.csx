#if !NOT_CSX
#load "../ConfigParser.csx"
#r "nuget: Scriban, 5.12.0"
#endif
using System;
using System.Text.RegularExpressions;
using System.IO;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using Scriban;
using Scriban.Runtime;
using System.Runtime.CompilerServices;

// https://globalcdn.nuget.org/packages/scriban.5.12.0.nupkg?packageVersion=5.12.0  lib/netstandard2.0/Scriban.dll
void Main() {
	//Console.WriteLine(String.Join("\n",Environment.GetCommandLineArgs()));Environment.Exit(0);
	var baseScript = Environment.GetEnvironmentVariable("WLB_SCRIPT_FOLDER");
	if (! string.IsNullOrWhiteSpace(baseScript))
		Environment.CurrentDirectory = baseScript;
	var config = new ConfigRead("default_config.ini");
	config.ReadConfig();
	var opts = new Opts(config);
	var bsgOpts = new BSGOpts(config);
	var showUsage = false;
	try {
		opts.CheckAllOpts();
	} catch (ArgumentException ex) {
		Console.Error.WriteLine("Invalid arg passed of: " + ex.ParamName);
		showUsage = true;
	}
	var usage = @"
	csi BuildScriptGenerator.csx
		This will generate an f_PROJNAME_build.sh script using the f_TEMPLATE_build.sbn-sh file (Scriban template).  You must specify at least --BUILD_NAME ProjName

		Some of the options to this script are taken directly from the default_config.ini by specifying them not only does it set that var for you, but it also will include the relevant template section in the build script (ie setting VCPKG_DEPS to any value will also add the code to install the packages to the build script).  All options must be past a value for boolean type options use 1 or 0, all values until the -- are considered the value for that option, it will automatically make it into an array where it should.

		While the options below are the common options technically you can specify any option in default_config.ini. When specifying an option you use its name without BLD_CONFIG_ prefix and case does not matter.

		The default value for each arg is in brackets.
		
		For array args you can specify multiple separated by spaces until the next arg";
	usage += "\n" + bsgOpts.UsageStr();

	var BUILD_NAME = opts.GetVal("BUILD_NAME");
	if (showUsage || String.IsNullOrWhiteSpace(BUILD_NAME)) {
		Console.Error.WriteLine(usage);
		Environment.Exit(1);
	}
	var templateText = File.ReadAllText("build/f_TEMPLATE_build.sbn-sh");
	var template = Template.Parse(templateText);
	var templateVals = new Dictionary<string,string>();
	config.PopulateDictionary(templateVals);
	var bld_vars = "";
	foreach (var opt in Enum.GetValues<BSG_OPT>()){
		templateVals[opt.ToString()] =  bsgOpts.GetVal(opts,opt);
	}
	foreach (var opt in opts.AllPassedConfigOpts){
		var val = GetOptVal(config,opts,opt);
		bld_vars += $"BLD_CONFIG_{opt}={val}\n";
		templateVals[opt] = val;
	}
	templateVals["GENERAL_BLD_CONFIG_VARS"] = bld_vars;
	var ourObj = new ScriptObject();
	ourObj.Import(typeof(OurScribanHelpers));

	var scriptObjs = new ScriptObject();
	scriptObjs["ours"] = ourObj;
	scriptObjs.Import(templateVals);

	var context = new TemplateContext();
	context.PushGlobal(scriptObjs);
	
	
	
	var full = template.Render(context).Replace("\r","");
	var blankRegex = new Regex(@"[ \t]*\n([ \t]*\n){2,}", RegexOptions.Singleline);
	full = blankRegex.Replace(full,"\n\n");

	var fname=@$"build/f_{BUILD_NAME}_build.sh";
	File.WriteAllText(fname,full);
	Console.WriteLine(full);
	Console.WriteLine($"DONE wrote: {fname}");

}


string GetOptVal(ConfigRead config, Opts opts, string opt) {
	var isArray = config.IsArray(opt);
	if (! isArray ){
		var val = opts.GetVal(opt);
		val=val.Replace("\"","\\\"");
		if (config.IsNumeric(opt))
			return val;
		return '"' + val + '"';
	}else{
		var arr = opts.GetArrVal(opt);
		if (arr.Count == 0)
			return "()";
		return $"( " + String.Join(" ",arr.Select(a=>'"' + a.Replace("\"","\\\"") + '"')) + " )";
	}
}

Main();

public class OurScribanHelpers {
	public static bool enabled(String val) => ! String.IsNullOrWhiteSpace(val) && val != "0";
}
enum BSG_OPT { GitRepo, HaveOurPatch }
class BSGOpts {
	public static bool IsValidOptName(string name, out BSG_OPT realName) => Enum.TryParse(name.Replace("_","").Replace("-",""),true, out realName);
	public static string GetRealOptNameStr(String name) => IsValidOptName(name, out var realName) ? realName.ToString() : null;
	public BSGOpts(ConfigRead config) {
		this.config = config;
	}
	public string GetVal(Opts opts, BSG_OPT name) => opts.HasVal(name.ToString()) ? opts.GetVal(name.ToString()) : AppOps.Single(a=>a.name == name).value.ToString();
	static BSGOpts() {
		AddOtherOpt(BSG_OPT.GitRepo, "Primary git repository for cloning", "https://github.com/mitchcapper/BUILD_APP_NAME.git");
		AddOtherOpt(BSG_OPT.HaveOurPatch, "Do we do our normal patch apply for this repo (needs repo patch file in patches dir)", 1);
	}
	public string UsageStr() {
		StringBuilder ret = new();
		foreach (var op in AppOps)
			ret.AppendLine($"--{op.name} [{op.value}] - {op.description}");

		foreach (var op in config_opts)
			ret.AppendLine($"--{config.GetRealName(op)} [{config.GetVal(op)}] - {config.GetComment(op)}");
		return ret.ToString();
	}
	public string[] config_opts = new []{
		"BUILD_NAME",
		"CMAKE_STYLE",
		"CONFIG_CMD_ADDL",
		"OUR_LIB_DEPS",
		"VCPKG_DEPS",
		"GNU_LIBS_USED",
		"GNU_LIBS_ADDL",
		"GNU_LIBS_BUILD_AUX_ONLY_USED",
		"BUILD_WINDOWS_COMPILE_WRAPPERS",
		"CONFIG_ADDL_LIBS",
		"ADD_WIN_ARGV_LIB",
		"BUILD_MSVC_RUNTIME_INFO_ADD_TO_C_AND_LDFLAGS",
		"CONFIG_NO_TESTS",
		"CONFIG_NO_PO",
		"CONFIG_NO_DOCS",
		"OUR_OS_FIXES_COMPILE",
		"OUR_OS_FIXES_APPLY_TO_DBG",
	};
	public class AppOp {
		public BSG_OPT name;
		public String description;
		public object value;
	}
	private static List<AppOp> AppOps = new();
	private ConfigRead config;

	public static void AddOtherOpt<T>(BSG_OPT name, String description, T defaultValue) {
		AppOps.Add(new AppOp() { description = description, name = name, value = defaultValue });
	}
}

class Opts {
	private ConfigRead config;

	public Opts(ConfigRead config) {
		this.config = config;
	}
	public bool HasVal(String name) => GetArrVal(name).Count != 0;
	public string GetVal(String name) {
		var vals = GetArrVal(name);
		if (vals.Count == 0)
			throw new Exception($"No value found for: {name}");
		if (vals.Count > 1)
			throw new Exception($"Expecting only one value for: {name} but got multiple: {String.Join(", ",vals)}");
		return vals[0];
	}

	public void CheckAllOpts() {
		GetArrVal("fullcheck"); // we will iterate everything and throw if any are invalid
	}
	public List<string> AllPassedConfigOpts=new();
	private readonly string[] OPTS_ALLOWED_TO_HAVE_UNESCAPED_DOUBLE_DASH_START = new []{"CONFIG_CMD_ADDL","CONFIG_CMD_ADDL_DEBUG","CONFIG_CMD_ADDL_STATIC","CONFIG_CMD_ADDL_SHARED","CONFIG_CMD_DEFAULT","CONFIG_CMD_GNULIB_ADDL", "GNU_LIBS_BOOTSTRAP_EXTRAS_ADD" };
	public List<string> GetArrVal(String name) {
		var ret = new List<string>();
		var including = false;
		var isFullCheck = name == "fullcheck";
		var RequestedOptRealName = BSGOpts.GetRealOptNameStr(name) ?? config.GetRealName(name);
		
		if (String.IsNullOrWhiteSpace(RequestedOptRealName) && ! isFullCheck)
			throw new Exception($"Internal error requesting a manual option of: {name} doesn't seem valid");
		string curOptName = null;
		foreach (var arg in Environment.GetCommandLineArgs()) {
			if (arg.StartsWith("--")) {
				var val = arg.Substring(2);
				var equalPos = val.IndexOf('=');
				string posNextValValue=null;
				string posOptName=val;
				if (equalPos != -1){
					posNextValValue = val.Substring(equalPos + 1).Trim();
					posOptName = val.Substring(0,equalPos).Trim();
				}
				var posBSGOptName = BSGOpts.GetRealOptNameStr(posOptName);
				var posConfigOptName = config.GetRealName(posOptName);
				var isValidOption = posBSGOptName != null || posConfigOptName != null;
				if (isValidOption)
					curOptName = posBSGOptName ?? posConfigOptName;
				if (OPTS_ALLOWED_TO_HAVE_UNESCAPED_DOUBLE_DASH_START.Any(a=>a==curOptName || "CMAKE_" + a == curOptName) && !isValidOption) { // essentially if its ./configure args we allow -- to be part of the array as long as its not a valid option name for us
				} else {
					if (!isValidOption)
						throw new ArgumentException(arg);
					if (isFullCheck && posConfigOptName != null)
						AllPassedConfigOpts.Add(posConfigOptName);
					including = curOptName == RequestedOptRealName;
					if (including && posNextValValue != null)
						ret.Add(posNextValValue);
					continue;
				}
			}
			if (including)
				ret.Add(arg);
		}
		return ret.Distinct().ToList();
	}
}
