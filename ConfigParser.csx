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
	public void ReadConfig() {
		if (!File.Exists(PROJ_file))
			throw new Exception($"Unable to find {PROJ_file} in current directory run /script/f_SCRIPTNAME_build.sh export_config to generate");
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
			}
			if (val.StartsWith("\"") && val.EndsWith("\""))
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
	public string GetComment(String name) => TryGetVar(name)?.comments;
}
