const fs=require('node:fs');
const path=require('node:path');
const root=path.resolve(__dirname,'..');
const remote=fs.readFileSync(path.join(root,'src/authorize.sh'),'utf8').replace(/\r\n/g,'\n');
const source=fs.readFileSync(path.join(root,'src/paseo-ssh.ps1'),'utf8').replace(/\r\n/g,'\n');
const output='\ufeff'+source.replace('__REMOTE_BASE64__',Buffer.from(remote).toString('base64'));
if(process.argv.includes('--check')) {
  if(fs.readFileSync(path.join(root,'paseo-ssh.ps1'),'utf8').replace(/\r\n/g,'\n')!==output) throw Error('Stale PowerShell build');
  console.log('PASS: BOM-marked single-file build matches sources');
} else {
  fs.writeFileSync(path.join(root,'paseo-ssh.ps1'),output);
  console.log('Built Windows PowerShell 5.1 / PowerShell 7 entry');
}
