var packages = File.ReadAllLines("packages.txt");
var orig_cont = File.ReadAllText("tool_build_template.yml.tmpl");
foreach (var package in packages){
    var arr = package.Trim().Split(new []{":"},StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
    var pkg_name = arr[0];
    if (String.IsNullOrWhiteSpace(pkg_name))
    	continue;
    var deps ="";
    if (arr.Length > 1){
    	var dep_arr = arr[1].Split(new []{" "},StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var tabs="        ";
		deps = $"RequiredDeps: |\n{tabs}" + string.Join("\n" + tabs,dep_arr);
	}
    var cont = orig_cont.Replace("[NAME]",pkg_name).Replace("[DEPS]",deps);
    File.WriteAllText($"workflows/tool_{pkg_name}_build.yml", cont);
}