const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const root = path.resolve(__dirname, '..');
const categories = [
  {name:'简介',dir:'01-introduction',description:'工具关系、首次搭建路线、复制约定'},
  {name:'安装部署',dir:'02-installation',description:'交互式一键安装、GitHub CLI 登录、Linux 依赖、PATH、工具安装'},
  {name:'远程连接',dir:'03-remote',description:'SSH 分步排障、主机指纹、Windows 密钥、SSH Agent、公钥认证、Paseo SSH'},
  {name:'项目与手机',dir:'04-projects-mobile',description:'Linux 路径、添加项目、二维码与 Relay'},
  {name:'模型与服务商',dir:'05-models',description:'服务商切换、模型缺少、手动添加、模型配置'},
  {name:'维护与排障',dir:'06-maintenance',description:'软件更新、daemon 启停、日常速查、错误与资料'},
];
function read(name) { return fs.readFileSync(path.join(root,name),'utf8'); }
function buildFiles() {
  const pages = JSON.parse(read('src/guide-content.json'));
  if (pages.length !== 29) throw new Error('Expected 29 articles');
  const ids = new Set();
  const location = new Map();
  for (const p of pages) {
    if (!/^[a-z0-9-]+$/.test(p.id) || ids.has(p.id)) throw new Error('Invalid or duplicate ID: '+p.id);
    ids.add(p.id);
    const group = categories.find(c=>c.name===p.group);
    if (!group) throw new Error('Unknown category: '+p.group);
    for (const key of ['title','description','platform']) if (!p[key]) throw new Error('Missing '+key+': '+p.id);
    if (!p.blocks?.length) throw new Error('Empty article: '+p.id);
    location.set(p.id,`docs/${group.dir}/${p.id}.md`);
    for (const b of p.blocks) {
      if (!['h2','p','list','code','note','table'].includes(b.type)) throw new Error('Unknown block: '+b.type);
      if (b.type==='code' && (/```|\]\(https?:|&#x20;|root@[^\n ]+:~#/.test(b.text))) throw new Error('Malformed command: '+p.id);
      if (b.type==='table' && b.rows.some(row=>row.length!==b.headers.length)) throw new Error('Invalid table: '+p.id);
    }
  }
  const files = new Map();
  const prose = value => String(value).replace(/\[(链接|网址)\]\(\1\)/g,match=>'`'+match+'`');
  const cell = value => String(value).replace(/\|/g,'\\|').replace(/\n/g,'<br>');
  const mdTable = (headers,rows) => [headers,headers.map(()=> '---'),...rows].map(row=>'| '+row.map(cell).join(' | ')+' |').join('\n');
  function renderBlock(b) {
    switch(b.type) {
      case 'h2': return '## '+b.text;
      case 'p': return prose(b.text);
      case 'code': return '**'+b.label+'**\n\n```'+(b.lang||'text')+'\n'+b.text+'\n```';
      case 'list': return b.items.map(s=>'- '+prose(s)).join('\n');
      case 'note': return '> **'+b.title+'**\n>\n'+b.text.split('\n').map(s=>'> '+prose(s)).join('\n');
      case 'table': return mdTable(b.headers,b.rows);
    }
  }
  function relative(from,to) { return path.posix.relative(path.posix.dirname(from),to); }
  pages.forEach((p,i)=>{
    const file=location.get(p.id);
    const nav=[`[返回首页](${relative(file,'README.md')})`,'[本分类目录](README.md)'];
    if(pages[i-1]) nav.push(`[上一篇：${pages[i-1].title}](${relative(file,location.get(pages[i-1].id))})`);
    if(pages[i+1]) nav.push(`[下一篇：${pages[i+1].title}](${relative(file,location.get(pages[i+1].id))})`);
    files.set(file,`# ${p.title}\n\n${nav.slice(0,2).join(' · ')}\n\n${p.description}\n\n执行位置：**${p.platform}** · 分类：${p.group}\n\n${p.blocks.map(renderBlock).join('\n\n')}\n\n---\n\n${nav.join(' · ')}\n`);
  });
  for (const c of categories) {
    const topics=pages.filter(p=>p.group===c.name);
    files.set(`docs/${c.dir}/README.md`,`# ${c.name}\n\n[返回首页](../../README.md) · [全部分类](../README.md)\n\n${c.description}\n\n`+topics.map((p,i)=>`${i+1}. [${p.title}](${p.id}.md) — ${p.description}`).join('\n')+'\n');
  }
  const categoryRows=categories.map(c=>[
    `[${c.name}](docs/${c.dir}/README.md)`,
    String(pages.filter(p=>p.group===c.name).length),
    c.description,
  ]);
  const categoryTable=mdTable(['分类','篇数','内容'],categoryRows);
  const readme=read('src/readme-template.md');
  if(!readme.includes('__CATEGORY_TABLE__')) throw new Error('Missing README placeholder');
  files.set('README.md',readme.replace('__CATEGORY_TABLE__',categoryTable));
  files.set('docs/README.md','# 全部分类\n\n[返回首页](../README.md)\n\n'+categoryTable.replaceAll('(docs/','(')+'\n');
  const template=read('src/guide-shell.html');
  if(!template.includes('__GUIDE_DATA__')) throw new Error('Missing guide placeholder');
  const html=template.replace('__GUIDE_DATA__',()=>JSON.stringify(pages).replace(/</g,'\\u003c'));
  const script=html.match(/<script>\s*([\s\S]*?)<\/script>/)?.[1];
  if(!script) throw new Error('Missing HTML app script');
  new vm.Script(script);
  if(/<script[^>]+src=|<link[^>]+stylesheet|fetch\(|XMLHttpRequest/i.test(html)) throw new Error('Offline guide has an external runtime dependency');
  files.set('index.html',html);
  return {files,pages,categories};
}
if (require.main===module) {
  const {files,pages,categories}=buildFiles();
  for(const [name,content] of files) {
    const target=path.join(root,name);
    fs.mkdirSync(path.dirname(target),{recursive:true});
    fs.writeFileSync(target,content,'utf8');
  }
  console.log(`Built ${pages.length} articles in ${categories.length} categories; ${files.size} generated files.`);
}
module.exports={buildFiles,root};
