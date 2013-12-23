/* 
* File system wrappers for Phonegap/Apache Cordova
* by Anthony W. Hursh, tony.hursh@gmail.com
* Copyright 2013 by Contraterrene eLearning Group, LLC
* Made available under the terms of the Apache 2.0 license
* (the same license as Phonegap/Cordova itself). See the NOTICE
* file for details.
*
* Public API:
*
* writeFile(fullpath, data, success, fail)
* Write data to a file.
* Parameters: 
*  fullpath: full path including file name (if no path portion is given, assumes /).
*      Examples: test.txt /test.txt /some/folder/test.txt
*  data: the data to write.
*  success: callback function on successful write. Called with the file URL as parameter.
*  fail: callback function if error occurs.
*
*
* appendFile(fullpath, data, success, fail)
* Identical to writeFile, except appends the data to an existing file.
*
* readFile(fullpath, asText, success,fail)
* Read data from a file.
* Parameters: 
*  fullpath: full path including file name (if no path portion is given, assumes /).
*      Examples: test.txt /test.txt /some/folder/test.txt
*  asText: boolean specifying whether to read as text or a data URI. If true,
*      calls success with the text as the parameter. If false, calls success with
*      the data URI as the parameter.
*  success: callback function on successful read. 
*  fail: callback function if error occurs.
*
* deleteFile(fullpath, success, fail)
* Delete a file
* Parameters: 
*  fullpath: full path of file to delete, including file name 
*  (if no path portion is given, assumes /).
*      Examples: test.txt /test.txt /some/folder/test.txt
*  success: callback function on successful delete.
*  fail: callback function if error occurs.
*
* readDirectory(dirName, success, fail)
* Get a list of the files in a directory.
* Parameters: 
*  dirName: full path to directory
*  success: callback function, called with an array of file names from the directory.
*  fail: callback function if error occurs.
*
* fileExists(fullpath, callback, faile)
* Check for file existence.
* Parameters: 
*  fullpath: full path of name to check
*  success: called with true if file is found, false if file is not found.
*  fail: callback function if error occurs.
*
* mkDirectory(dirName, success, fail)
* Create a subdirectory.
* Parameters: 
*  dirName: full path to directory
*  success: callback function for successful create.
*  fail: callback function if error occurs.
*
* rmDirectory(dirName, success, fail)
* Delete a subdirectory.
* Parameters: 
*  dirName: full path to directory
*  success: callback function for successful delete.
*  fail: callback function if error occurs.
*
*/


/* Changelog:  writeFile now returns the File URL on successful write. */

var gapFile = {
		extractDirectory: function(path){
		var dirPath;
		var lastSlash = path.lastIndexOf('/');
		if(lastSlash == -1){
			dirPath = "/";
		}
		else{
			dirPath = path.substring(0,lastSlash);
			if(dirPath == ""){
				dirPath = "/";
			}
		}
		return dirPath;
	},

	extractFilename: function(path){
		var lastSlash = path.lastIndexOf('/');
		if(lastSlash == -1){
			return path;
		}
		var filename =  path.substring(lastSlash + 1);
		return filename;
	},

	appendFile: function(fullpath,data,success,fail){
		this.llWriteFile(fullpath,data,success,fail,true);
	},
	
	writeFile: function(fullpath,data,success,fail){
		this.llWriteFile(fullpath,data,success,fail,false);
	},
	
	llWriteFile: function(fullpath,data,success,fail,append){
		window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, 
			function(fileSystem){
				fileSystem.root.getDirectory(gapFile.extractDirectory(fullpath), {create: true, exclusive: false},
				function(dirEntry){
					dirEntry.getFile(gapFile.extractFilename(fullpath), {create: true}, 
					function(fileEntry){
							var fileURL = fileEntry.toURL();
							fileEntry.createWriter(
								function(writer){
									writer.onwrite = function(evt){
										success(fileURL);
									};
									writer.onerror = function(evt){ 
										fail(evt.target.error);
									};
									if(append == true){
										writer.seek(writer.length);
									}
									writer.write(data);
							},fail);
					},fail);
				},fail);
			},fail);
	},
	readFile: function(fullpath,asText,success,fail){
		window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, 
			function(fileSystem){
				fileSystem.root.getDirectory(gapFile.extractDirectory(fullpath), {create: false, exclusive: false},
				function(dirEntry){
					dirEntry.getFile(gapFile.extractFilename(fullpath), {create: false}, 
					function(fileEntry){
						fileEntry.file(function(file){
							var reader = new FileReader();
							reader.onloadend = function(evt) {
								success(evt.target.result);
							};
							reader.onerror =  function(evt){
								fail();
							}
							if(asText){
								reader.readAsText(file);
							}
							else{
								reader.readAsDataURL(file);
							}
							},fail);
						},fail);
					},fail);
				},fail);
	},
	
	deleteFile: function(fullpath,success,fail){
			window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, 
				function(fileSystem){
					fileSystem.root.getDirectory(gapFile.extractDirectory(fullpath), {create: false, exclusive: false},
					function(dirEntry){
						dirEntry.getFile(gapFile.extractFilename(fullpath), {create: false}, 
						function(fileEntry){
							fileEntry.remove(success,fail);
						},fail);
					},fail);
				},fail);
	},
	readDirectory: function(dirName,success,fail){
		window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, 
			function(fileSystem){
				fileSystem.root.getDirectory(dirName, {create: false, exclusive: false},
					function(dirEntry){
						var directoryReader = dirEntry.createReader();
						directoryReader.readEntries(
							function(entries){
								var flist = [];
								for(var i = 0; i < entries.length; i++){
									flist.push(entries[i].name);
								}
								success(flist);
							},fail);
					},fail);
			},fail);       
	},
	
	
	mkDirectory: function(dirName,success,fail){
		window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, 
			function(fileSystem){
		        fileSystem.root.getDirectory(dirName, {create: true, exclusive: false}, success, fail);
			},fail);
	},
	
	rmDirectory: function(dirName,success,fail){
		window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, 
			function(fileSystem){
		        fileSystem.root.getDirectory(dirName, {create: false, exclusive: false}, 
						function(dirEntry){
							dirEntry.remove(success,fail);
						},fail);
				},fail)
	},

	fileExists: function(fullpath,success,fail){
		var dirName = this.extractDirectory(fullpath);
		var fileName = this.extractFilename(fullpath);
		this.readDirectory(dirName,function(flist){
			for(var i = 0; i < flist.length; i++ ){
				if(flist[i].match(fileName)){
					success(true);
					return;
				}
			}
			success(false);
		},fail); 
	},


  copyDirectory: function(source, destination, success, fail) {
    return window.requestFileSystem(LocalFileSystem.PERSISTENT, 0, function(fileSystem) {
      return fileSystem.root.getDirectory(source, {
        create: true,
        exclusive: false
      }, function(dirEntry) {
        return dirEntry.copyTo(destination, null, success, fail);
      }, fail);
    }, fail);
  }

};

