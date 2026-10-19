const fs=require('node:fs');
const path=require('node:path');
const vm=require('node:vm');
const {buildFiles,root}=require('./build.cjs');
const {files,pages,categories}=buildFiles();
const failures=[];
const normalize=s=>s.replace(/\r\n/g,'\n');
for(const [name,expected] of files) {
  const file=path.join(root,name);
  if(!fs.existsSync(file)) failures.push('Missing generated file: '+name);
  else if(normalize(fs.readFileSync(file,'utf8'))!==normalize(expected)) failures.push('Stale output: '+name);
  if(name.endsWith('.md')) {
    const withoutCode=expected.replace(/```[\s\S]*?```/g,'').replace(/`[^`]+`/g,'');
    for(const match of withoutCode.matchAll(/\[[^\]]+\]\(([^)]+)\)/g)) {
      const target=match[1].split('#')[0];
      if(!target || /^(https?:|mailto:)/.test(target)) continue;
      const resolved=path.resolve(path.dirname(file),target);
      if(!resolved.startsWith(root+path.sep) || !fs.existsSync(resolved)) failures.push(`Broken internal link: ${name} -> ${target}`);
    }
  }
}
function walk(dir) {
  return fs.readdirSync(dir,{withFileTypes:true}).flatMap(e=>{
    if(['.git','node_modules'].includes(e.name)) return [];
    const file=path.join(dir,e.name);
    if(e.isSymbolicLink()) { failures.push('Unexpected symlink: '+file);return []; }
    return e.isDirectory()?walk(file):[file];
  });
}
const all=walk(root);
for(const file of all) {
  const relative=path.relative(root,file);
  if(!/\.(md|json|html|cjs|sh|yml)$|^\.(gitignore|gitattributes)$/.test(relative)) failures.push('Unexpected repository file: '+relative);
  const text=fs.readFileSync(file,'utf8');
  const secretPatterns=[
    /-----BEGIN (?:RSA |EC |OPENSSH )?PRIVATE KEY-----/,
    /\b(?:gh[pousr]_[A-Za-z0-9]{20,}|github_pat_[A-Za-z0-9_]{20,}|sk-[A-Za-z0-9_-]{20,})\b/,
    /(?:password|api_key|access_token)\s*["']?\s*[:=]\s*["'][A-Za-z0-9_+\/-]{16,}["']/i,
  ];
  if(secretPatterns.some(re=>re.test(text))) failures.push('Possible credential in '+relative);
  if(!relative.startsWith('scripts'+path.sep)) {
    const ips=text.match(/\b(?:\d{1,3}\.){3}\d{1,3}\b/g)||[];
    if(ips.some(ip=>!['127.0.0.1','0.0.0.0'].includes(ip))) failures.push('Non-example IP in '+relative);
    if(/C:\\+Users\\+(?!WINDOWS_USER\b)[A-Za-z0-9_.-]+/.test(text)) failures.push('Personal Windows home path in '+relative);
  }
  if(file.endsWith('.cjs')) new vm.Script(text,{filename:relative});
}
const codeBlocks=pages.flatMap(p=>p.blocks).filter(b=>b.type==='code').length;
if(failures.length) { console.error(failures.join('\n'));process.exitCode=1; }
else console.log(`PASS: ${pages.length} articles, ${categories.length} categories, ${codeBlocks} command/example blocks, ${all.length} files; links, deterministic outputs, offline script and credential checks passed.`);
