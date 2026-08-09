import {spawn} from 'node:child_process';

const input=process.argv.slice(2);
let host='0.0.0.0';
let port='4173';
for(let index=0;index<input.length;index+=1){
  if(input[index]==='--host'&&input[index+1]) host=input[++index];
  else if(input[index]==='--port'&&input[index+1]) port=input[++index];
}

const child=spawn(process.platform==='win32'?'npx.cmd':'npx',['next','dev','--hostname',host,'--port',port],{stdio:'inherit'});
child.on('exit',code=>process.exit(code??0));
