package {
    
    import com.bit101.components.CheckBox;
    import com.bit101.components.InputText;
    import com.bit101.components.PushButton;
    import com.bit101.components.Style;
    import com.bit101.components.TextArea;
    import com.bit101.utils.MinimalConfigurator;
    
    import flash.display.Sprite;
    import flash.events.Event;
    import flash.events.MouseEvent;
    import flash.filesystem.File;
    import flash.filesystem.FileMode;
    import flash.filesystem.FileStream;
    import flash.utils.setTimeout;
    
    public class Main extends Sprite {
        private var _uiConfig:MinimalConfigurator;
        private var _logTextArea:TextArea;
        private var exportFiles:Vector.<File>;
        
        private var _langObj:Object = new Object();
        
        public function Main() {
            Style.embedFonts = false;
            
            _uiConfig = new MinimalConfigurator(this);
            _uiConfig.loadXML("assets/UIConfig.xml");
            _uiConfig.addEventListener("complete", loadXmlComplete);
        }
        
        private function loadXmlComplete(param1:Event):void {
            _logTextArea = _uiConfig.getCompById("logs") as TextArea;
            _logTextArea.editable = false;
        }
        
        public function onSelectSource(e:MouseEvent):void {
            var file:File = new File();
            file.browseForDirectory("选择源路径");
            file.addEventListener("select", selectSourceComplete);
        }
        
        private function selectSourceComplete(e:Event):void {
            var file:File = e.target as File;
            file.removeEventListener("select", selectSourceComplete);
            (_uiConfig.getCompById("sourceDir") as InputText).text = file.nativePath + "\\";
        }
        
        public function onSelectExport(e:MouseEvent):void {
            var file:File = new File();
            file.browseForDirectory("选择输出路径");
            file.addEventListener("select", selectExportComplete);
        }
        
        private function selectExportComplete(e:Event):void {
            var file:File = e.target as File;
            file.removeEventListener("select", selectExportComplete);
            (_uiConfig.getCompById("exportDir") as InputText).text = file.nativePath + "\\";
            
        }
        
        public function onExport(e:MouseEvent):void {
            if (sourceDir == "[object InputText]") {
                log("源目录不能为空！！！");
                return;
            }
            if (exportDir == "[object InputText]") {
                log("输出目录不能为空！！！");
                return;
            }
            if (sourceDir == exportDir) {
                log("源目录和输出目录不能相同！！！");
                return;
            }
            (_uiConfig.getCompById("export") as PushButton).enabled = false;
            exportFiles = new Vector.<File>();
            ergodicDirectory(new File(sourceDir));
            clearLogs();
            log("开始转换...\n");
            log("总共选择了" + exportFiles.length + "个文件.\n");
            if (exportFiles.length == 0) {
                log("导出完毕.\n");
                exportBtnEnabled = true;
            }
            else {
                _langObj=new Object();
                setTimeout(function ():void {
                    var boolRevert:Boolean = (_uiConfig.getCompById("revert") as CheckBox).selected;
                    if(boolRevert){
                        startExport1(exportFiles.pop());
                    }else {
                        startExport(exportFiles.pop());
                    }
                }, 600);
            }
        }
        /**
         * 导出  //目前能处理除了html字符串的其他包含中文的字符串，html字符串"<font color="#19a619">(已领取)</font>"这种无法识别
         * */
        private function startExport(file:File):void {
            log("\n" + file.name + "开始转换...剩余:" + exportFiles.length + "个文件...\n");
            var resultStringArr:Array = [];
            var readFile:FileStream = new FileStream();
            readFile.open(file, FileMode.READ);
            var sourceString:String = readFile.readUTFBytes(readFile.bytesAvailable);
            var targetString:String = sourceString;
            readFile.close();
            var regx:RegExp = /"[^"\/\/]*[\u4e00-\u9fa5]+[^"\/\/]*"/g;
            var obj:* = regx.exec(sourceString);
            while (obj) {
                var cutIndex:int = targetString.indexOf(obj[0]);
                var cutString:String = targetString.substr(0, cutIndex + obj[0].length);
                cutString = cutString.replace(obj[0], "Lang.Get(" + obj[0] + ")");
                resultStringArr.push(cutString);
                targetString = targetString.substr(cutIndex + obj[0].length);
                if(!_langObj[obj[0]]){
                    _langObj[obj[0]] = obj[0];
                }
                obj = regx.exec(sourceString);
                trace(obj);
            }
            var resultString:String = "";
            if (resultStringArr.length > 0) {
                for (var i:int = 0; i < resultStringArr.length; i++) {
                    resultString += resultStringArr[i];
                }
            }
            resultString += targetString;
            var path:String = file.nativePath.replace(sourceDir, exportDir);
            var newFile:File = new File(path);
            if (!newFile.exists) {
//                    file.copyTo(newFile, true);
            } else {
                newFile.deleteFile();
            }
            var fileStream:FileStream = new FileStream();
            fileStream.open(newFile, FileMode.WRITE);
            fileStream.writeUTFBytes(resultString);
            fileStream.close();
            if (exportFiles.length > 0) {
                var boolRevert:Boolean = (_uiConfig.getCompById("revert") as CheckBox).selected;
                if(boolRevert){
                    startExport1(exportFiles.pop());
                }else {
                    startExport(exportFiles.pop());
                }
            }
            else {
                log("开始构建lang文件...\n");
                var langString:String = JSON.stringify(_langObj);
                langString = langString.replace(/\\"/g, "");
                trace(langString);
//                var langFile:File=new File(exportDir);
                var langFS:FileStream = new FileStream();
                langFS.open(new File(exportDir + "lang.json"), FileMode.WRITE);
                langFS.writeUTFBytes(langString);
                langFS.close();
                log("导出完毕.\n");
                exportBtnEnabled = true;
            }
        }
        /**还原*/
        private function startExport1(file:File):void {
            log("\n" + file.name + "开始转换...剩余:" + exportFiles.length + "个文件...\n");
            var resultStringArr:Array = [];
            var readFile:FileStream = new FileStream();
            readFile.open(file, FileMode.READ);
            var sourceString:String = readFile.readUTFBytes(readFile.bytesAvailable);
            var targetString:String = sourceString;
            readFile.close();
            var regx:RegExp = /Lang.Get\(\"[^Lang.Get\"\)]+\"\)/g;
            var obj:* = regx.exec(sourceString);
            while (obj) {
                var cutIndex:int = targetString.indexOf(obj[0]);
                var cutString:String = targetString.substr(0, cutIndex + obj[0].length);
                var regx1:RegExp=/"[^"\/\/]*[\u4e00-\u9fa5]+[^"\/\/]*"/g;
                var obj1:*=regx1.exec(obj[0]);
                cutString = cutString.replace(obj[0], obj1[0]);
                resultStringArr.push(cutString);
                targetString = targetString.substr(cutIndex + obj[0].length);
                obj = regx.exec(sourceString);
                trace(obj);
            }
            var resultString:String = "";
            if (resultStringArr.length > 0) {
                for (var i:int = 0; i < resultStringArr.length; i++) {
                    resultString += resultStringArr[i];
                }
            }
            resultString += targetString;
            var path:String = file.nativePath.replace(sourceDir, exportDir);
            var newFile:File = new File(path);
            if (!newFile.exists) {
//                    file.copyTo(newFile, true);
            } else {
                newFile.deleteFile();
            }
            var fileStream:FileStream = new FileStream();
            fileStream.open(newFile, FileMode.WRITE);
            fileStream.writeUTFBytes(resultString);
            fileStream.close();
            if (exportFiles.length > 0) {
                var boolRevert:Boolean = (_uiConfig.getCompById("revert") as CheckBox).selected;
                if(boolRevert){
                    startExport1(exportFiles.pop());
                }else {
                    startExport(exportFiles.pop());
                }
            }
            else {
                log("导出完毕.\n");
                exportBtnEnabled = true;
            }
        }
        
        public function set exportBtnEnabled(param1:Boolean):void {
            (_uiConfig.getCompById("export") as PushButton).enabled = param1;
        }
        
        public function log(param1:String):void {
            _logTextArea.text += param1;
        }
        
        public function set sourceDir(param1:String):void {
            (_uiConfig.getCompById("sourceDir") as InputText).text = param1;
        }
        
        public function get sourceDir():String {
            return (_uiConfig.getCompById("sourceDir") as InputText).text;
        }
        
        public function set exportDir(param1:String):void {
            (_uiConfig.getCompById("exportDir") as InputText).text = param1;
        }
        
        public function get exportDir():String {
            return (_uiConfig.getCompById("exportDir") as InputText).text;
        }
        
        private function ergodicDirectory(file:File):void {
            var obj:* = null;
            var index:int = 0;
            var dirArr:Array = file.getDirectoryListing();
            var len:int = dirArr.length;
            index = 0;
            while (index < len) {
                obj = dirArr[index];
                var pathArr:Array = File(obj).nativePath.split("\\");
                if (obj.isDirectory && pathArr[pathArr.length - 1] != "ui") {
                    createDir(obj);
                    ergodicDirectory(obj);
                }
                else if (obj.extension == "ts") {
                    exportFiles.push(obj);
                }
                index++;
            }
        }
        
        public function clearLogs():void {
            _logTextArea.text = "";
        }
        
        private function createDir(file:File):void {
            var path:String = file.nativePath.replace(sourceDir, exportDir);
            var newFile:File = new File(path);
            if (!newFile.exists) {
                newFile.createDirectory();
            }
        }
        
        private function copyFile(file:File):void {
            var path:String = file.nativePath.replace(sourceDir, exportDir);
            var newFile:File = new File(path);
            if (!newFile.exists) {
                file.copyTo(newFile, true);
            }
        }
    }
}
