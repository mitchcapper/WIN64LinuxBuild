var packages = File.ReadAllLines("packages.txt");
var orig_cont = File.ReadAllText("tool_build_template.yml.tmpl");
foreach (var package in packages){
    var arr = package.Trim().Split(new []{":"},StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
    var pkg_name = arr[0];
    if (String.IsNullOrWhiteSpace(pkg_name))
    	continue;
    var deps = arr.Length > 1 ? arr[1] : "";
    var noDebug=false;
    if (deps.Contains("-NoDebug")){
        deps = deps.Replace("-NoDebug","");
        noDebug=true;
    }
    if (! string.IsNullOrWhiteSpace(deps)){
    	var dep_arr = deps.Split(new []{" "},StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries);
        var tabs="        ";
       
		deps = $"RequiredDeps: |\n{tabs}" + string.Join("\n" + tabs,dep_arr);
	}
    if (noDebug)
        deps +="\n      NoDebugBuild: true";
    deps = deps.Trim();
    var cont = orig_cont.Replace("[NAME]",pkg_name).Replace("[DEPS]",deps);
    File.WriteAllText($"workflows/tool_{pkg_name}_build.yml", cont);
}