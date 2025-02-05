using System;
using System.Collections.Generic;
using System.IO;
using System.Text.RegularExpressions;

class ConfigRead {
	private class ConfigVar {
		public string name;
		public string value;
		public string comments;
		public bool isNumeric;
		public bool isArrayItem;

	}
	public ConfigRead(String config_file) {
		PROJ_file = config_file;
	}
	public void PopulateDictionary(Dictionary<string, string> dict) {
		foreach (var kvp in items)
			dict[kvp.Value.name] = kvp.Value.value;
	}
	Dictionary<string, ConfigVar> items = new();
	private string NameToKey(String name) {
		return name.ToLower().Replace("-", "").Replace("_", "");
	}
	private string PROJ_file;
	public string GenerateSuggestedExportCmd(){
		var scriptName = Path.GetFileName(Directory.GetCurrentDirectory());
		var scriptDir = Environment.GetEnvironmentVariable("WLB_SCRIPT_FOLDER");
		if (string.IsNullOrWhiteSpace(scriptDir))
			scriptDir ="/script";
		var finalPath = Path.Combine(scriptDir,"build",$"f_{scriptName}_build.sh");
		Console.WriteLine($"Trying: {finalPath}");
		if (! File.Exists(finalPath))
			finalPath = Path.Combine(scriptDir,"build",$"f_SCRIPT_NAME_build.sh");
		finalPath = finalPath.Replace("\\","/");
		return $"{finalPath} export_config";
	}
	public void ReadConfig() {
		if (!File.Exists(PROJ_file))
			throw new Exception($"Unable to find {PROJ_file} in current directory run the build script with the arg export_config to generate, IE: " + GenerateSuggestedExportCmd());
		var lines = File.ReadAllLines(PROJ_file);
		ConfigVar lastVar = null;
		foreach (var _line in lines) {
			var line = _line;
			string lineComment = null;
			var commentStart = line.IndexOf("#");
			if (commentStart != -1) {
				var lineBefore = line.Substring(0, commentStart);
				lineComment = line.Substring(commentStart + 1).Trim();
				if (lineBefore.Length > 2 && String.IsNullOrWhiteSpace(lineBefore) && lastVar != null) //if an indented comment append to prior
					lastVar.comments += "\n\t" + lineComment;
				line = lineBefore;
			}
			if (!line.Contains("="))
				continue;
			var arr = line.Split(new[] { "=" }, 2, StringSplitOptions.None);
			var val = arr[1].Trim();
			var isArrayItem = false;
			if (val.StartsWith("(")){
				isArrayItem= true;
				val = val.Substring(1, val.Length - 2).Trim();
			} else if (val.StartsWith("\"") && val.EndsWith("\"")) //dont dequote array items by default
				val = val.Substring(1, val.Length - 2).Trim();
			var name = arr[0].Trim();
			
			
			
			items[NameToKey(name)] = new ConfigVar() { name = name, comments = lineComment, isNumeric = IsNumber(val), isArrayItem=isArrayItem, value=val };
		}
	}
	public static bool IsNumber(String val) => NumbersOnly.IsMatch(val);
	private static Regex NumbersOnly = new Regex(@"^[0-9\-][0-9.\-]*$");
	private ConfigVar TryGetVar(String name) => items.TryGetValue(NameToKey(name), out var value) ? value : null;
	public bool GetTrue(String name) {
		var val = GetVal(name);
		return (!String.IsNullOrWhiteSpace(val) && (val == "true" || val == "1"));
	}
	public bool OptionExists(String name) => TryGetVar(name) != null;
	public bool IsArray(String name) => TryGetVar(name)?.isArrayItem ?? false;
	public bool IsNumeric(String name) => TryGetVar(name)?.isNumeric ?? false;
	public string GetRealName(String name) => TryGetVar(name)?.name;
	public string GetVal(String name) => TryGetVar(name)?.value;

	/// <summary>
	/// doesn't do great at handling escaped quotes beware
	/// </summary>
	/// <param name="name"></param>
	/// <returns></returns>
	public string[] GetArrParse(String name) {
		var val = GetVal(name);
		if (String.IsNullOrWhiteSpace(val))
			return new string[0];

		var matches = Regex.Matches(val, @"""(?:[^""\\]|\\.)*""|[^\s""]+");

		var ret = new List<string>();
		foreach (Match match in matches) {
			var value = match.Value;
			if (value.StartsWith("\"")) {
				value = value.Trim('"');
				value = Regex.Replace(value, @"\\([""])", "$1");//deslash the quote itself if has escaped inside quote
			}
			ret.Add(value);
		}
		return ret.ToArray();
	}
	public string GetComment(String name) => TryGetVar(name)?.comments;
}
