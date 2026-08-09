'use client';

import {useEffect,useMemo,useState} from 'react';
import {
  Activity,AlertCircle,ArrowRight,BarChart3,Bell,Box,BriefcaseBusiness,Building2,CalendarDays,
  Check,CheckCircle2,ChevronDown,ChevronRight,CircleGauge,ClipboardCheck,
  Clock3,Cpu,FileCheck2,FileText,Home,ImagePlus,LifeBuoy,LogOut,Menu,
  PackageCheck,Plus,QrCode,RefreshCw,Search,Settings,ShieldCheck,Smartphone,
  Sparkles,TriangleAlert,UserRound,UsersRound,Wrench,X
} from 'lucide-react';
import {
  addProduct,advanceRepair,changeDemoRole,createRepair,firebaseConfigured,
  getDemoSession,loadWorkspace,observeAccount,openDemo,registerAccount,
  repairStages,signInAccount,signOutAccount
} from '../lib/repairloopService';

const roleMeta={
  customer:{label:'Customer',workspace:'Personal device care',accent:'#176b61'},
  manufacturer:{label:'Manufacturer',workspace:'Product reliability',accent:'#295d8a'},
  technician:{label:'Technician',workspace:'Service operations',accent:'#9a5a20'},
  administrator:{label:'Administrator',workspace:'Platform control',accent:'#81506f'}
};

const navByRole={
  customer:[['Overview',Home],['My products',Cpu],['Repair cases',BriefcaseBusiness],['Diagnostics',Sparkles],['Passports',QrCode]],
  manufacturer:[['Overview',Home],['Product fleet',Box],['Service insights',BarChart3],['Bulletins',FileText],['Passport records',QrCode]],
  technician:[['Work queue',ClipboardCheck],['Appointments',CalendarDays],['Parts & tasks',PackageCheck],['Completed jobs',CheckCircle2]],
  administrator:[['Platform overview',Home],['User access',UsersRound],['Passport review',FileCheck2],['Safety cases',ShieldCheck],['Configuration',Settings]]
};

function analyseSymptoms(symptoms){
  const text=symptoms.toLowerCase();
  if(/hot|heat|fan|overheat/.test(text)) return {finding:'Cooling system airflow restriction',confidence:88,urgency:'Priority',summary:'The reported heat and fan behaviour is consistent with restricted airflow, dust buildup, or a worn cooling fan.',estimate:'₹600–₹1,800',time:'1–2 hours',actions:['Pause heavy workloads','Back up important files','Arrange a cooling-system inspection']};
  if(/battery|charge|drain|power/.test(text)) return {finding:'Battery or charging-system fault',confidence:84,urgency:'Standard',summary:'The power symptoms may be caused by battery wear, a damaged charging accessory, or the charging circuit.',estimate:'₹900–₹4,500',time:'2–4 hours',actions:['Test with a verified charger','Avoid unattended charging','Request a battery health test']};
  if(/screen|display|flicker|line/.test(text)) return {finding:'Display connection or panel fault',confidence:81,urgency:'Standard',summary:'The display symptoms may come from a loose internal connector, software driver, or damaged panel.',estimate:'₹800–₹6,000',time:'2–5 hours',actions:['Restart the device once','Do not press the display panel','Arrange a display inspection']};
  return {finding:'Physical inspection required',confidence:72,urgency:'Standard',summary:'The description is not specific enough for a safe component-level recommendation. A structured inspection is the correct next step.',estimate:'₹400–₹2,500',time:'1–3 hours',actions:['Back up important data','Do not open the device','Book a qualified technician']};
}

function formatDate(value){
  if(!value) return 'Not available';
  const date=new Date(value);
  return Number.isNaN(date.getTime())?String(value):new Intl.DateTimeFormat('en-IN',{day:'2-digit',month:'short',year:'numeric'}).format(date);
}

function Logo(){return <div className="logo"><span><Wrench size={19}/></span><b>RepairLoop</b></div>}

function AuthScreen({onAuthenticated}){
  const [mode,setMode]=useState('signin');
  const [form,setForm]=useState({name:'',email:'',password:''});
  const [error,setError]=useState('');
  const [busy,setBusy]=useState(false);
  async function submit(event){
    event.preventDefault();setBusy(true);setError('');
    try{
      if(!form.email||form.password.length<6) throw new Error('Enter a valid email and a password with at least 6 characters.');
      if(mode==='register'&&!form.name.trim()) throw new Error('Enter your full name.');
      const account=mode==='register'?await registerAccount(form):await signInAccount(form);
      onAuthenticated(account);
    }catch(nextError){setError(nextError.message);setBusy(false)}
  }
  return <main className="auth-page">
    <section className="auth-context">
      <Logo/>
      <div className="auth-message">
        <p className="kicker">PRODUCT LIFECYCLE & REPAIR OPERATIONS</p>
        <h1>A verified service record for every device.</h1>
        <p>Register ownership, diagnose faults, coordinate repairs, and preserve the complete product history in one dependable workspace.</p>
        <div className="auth-proof">
          <div><ShieldCheck/><span><b>Portable product passports</b><small>Ownership, warranty, components, and repairs stay together.</small></span></div>
          <div><BriefcaseBusiness/><span><b>Traceable repair cases</b><small>Customers and service teams work from the same timeline.</small></span></div>
          <div><FileCheck2/><span><b>Responsible decisions</b><small>Repair-first guidance reduces premature replacement.</small></span></div>
        </div>
      </div>
      <p className="auth-foot">Designed for customers, manufacturers, service teams, and platform operators.</p>
    </section>
    <section className="auth-access">
      <div className="mobile-logo"><Logo/></div>
      <div className="auth-card">
        <div className="auth-tabs"><button className={mode==='signin'?'active':''} onClick={()=>{setMode('signin');setError('')}}>Sign in</button><button className={mode==='register'?'active':''} onClick={()=>{setMode('register');setError('')}}>Create account</button></div>
        <h2>{mode==='signin'?'Welcome back':'Create your RepairLoop account'}</h2>
        <p>{mode==='signin'?'Access your products and active service cases.':'Start a permanent, verified care record for your products.'}</p>
        <form onSubmit={submit}>
          {mode==='register'&&<label>Full name<input autoComplete="name" value={form.name} onChange={event=>setForm({...form,name:event.target.value})} placeholder="Your full name"/></label>}
          <label>Email address<input type="email" autoComplete="email" value={form.email} onChange={event=>setForm({...form,email:event.target.value})} placeholder="name@example.com"/></label>
          <label>Password<input type="password" autoComplete={mode==='signin'?'current-password':'new-password'} value={form.password} onChange={event=>setForm({...form,password:event.target.value})} placeholder="Minimum 6 characters"/></label>
          {error&&<div className="form-alert"><AlertCircle/>{error}</div>}
          <button className="button primary-button" disabled={busy}>{busy?'Please wait…':mode==='signin'?'Sign in':'Create account'} <ArrowRight/></button>
        </form>
        <div className="auth-divider"><span>or review the product</span></div>
        <button className="button demo-button" onClick={()=>onAuthenticated(openDemo())}>Open demo workspace</button>
        <div className="backend-status"><span className={firebaseConfigured?'online':'demo'}></span><div><b>{firebaseConfigured?'Firebase connected':'Demo data active'}</b><small>{firebaseConfigured?'Authentication and Firestore are ready.':'Connect Firebase keys to enable real accounts and cloud sync.'}</small></div></div>
      </div>
    </section>
  </main>;
}

function Sidebar({session,active,setActive,onSignOut}){
  const meta=roleMeta[session.role]||roleMeta.customer;
  return <aside className="sidebar">
    <Logo/>
    <div className="workspace-tag"><span style={{background:meta.accent}}>{meta.label[0]}</span><div><small>WORKSPACE</small><b>{meta.workspace}</b></div></div>
    <nav>{navByRole[session.role].map(([label,Icon])=><button key={label} className={active===label?'active':''} onClick={()=>setActive(label)}><Icon/>{label}</button>)}</nav>
    <div className="sidebar-help"><LifeBuoy/><div><b>Service support</b><small>Help with a case or passport</small></div><ChevronRight/></div>
    <button className="sidebar-user" onClick={onSignOut}><span>{session.name.split(' ').map(part=>part[0]).join('').slice(0,2)}</span><div><b>{session.name}</b><small>{meta.label} · Sign out</small></div><LogOut/></button>
  </aside>;
}

function Topbar({session,onRoleChange,onRefresh,onMenu}){
  const [open,setOpen]=useState(false);
  return <header className="topbar">
    <button className="icon-button menu-button" aria-label="Open navigation" onClick={onMenu}><Menu/></button>
    <div className="search-field"><Search/><input aria-label="Search RepairLoop" placeholder="Search product, passport, serial, or repair ID"/></div>
    <div className="topbar-actions"><span className="sync-state"><span></span>{session.mode==='firebase'?'Cloud synced':'Demo workspace'}</span><button className="icon-button" aria-label="Refresh data" onClick={onRefresh}><RefreshCw/></button><button className="icon-button has-notice" aria-label="Notifications"><Bell/><i></i></button>
      {session.mode==='demo'&&<div className="role-menu"><button className="role-trigger" onClick={()=>setOpen(!open)}><span>{roleMeta[session.role].label}</span><ChevronDown/></button>{open&&<div className="role-popover">{Object.entries(roleMeta).map(([role,meta])=><button key={role} className={role===session.role?'selected':''} onClick={()=>{onRoleChange(role);setOpen(false)}}><span style={{background:meta.accent}}></span>{meta.label}{role===session.role&&<Check/>}</button>)}</div>}</div>}
    </div>
  </header>;
}

function Metric({label,value,detail,Icon,tone}){return <article className="metric"><span className={tone}><Icon/></span><div><small>{label}</small><b>{value}</b><p>{detail}</p></div></article>}

function RepairProgress({repair}){
  return <div className="repair-progress">{repairStages.map((stage,index)=><div key={stage} className={index<repair.stage?'complete':index===repair.stage?'current':''}><i>{index<repair.stage?<Check/>:index+1}</i><span>{stage}</span></div>)}</div>;
}

function CustomerOverview({session,data,onRegister,onDiagnose}){
  const activeRepair=data.repairs.find(repair=>repair.stage<repairStages.length-1);
  const selectedProduct=data.products.find(product=>product.id===activeRepair?.productId)||data.products[0];
  const averageHealth=data.products.length?Math.round(data.products.reduce((sum,item)=>sum+Number(item.health||0),0)/data.products.length):0;
  return <>
    <div className="page-heading"><div><p className="kicker">CUSTOMER OVERVIEW</p><h1>Device care dashboard</h1><p>Monitor product condition, service activity, and verified lifecycle records.</p></div><div className="heading-actions"><button className="button secondary-button" onClick={onRegister}><Plus/> Register product</button><button className="button primary-button" onClick={onDiagnose}><Sparkles/> Start diagnosis</button></div></div>
    <div className="metric-grid"><Metric label="REGISTERED PRODUCTS" value={data.products.length} detail="Across your RepairLoop account" Icon={Cpu} tone="teal"/><Metric label="AVERAGE HEALTH" value={`${averageHealth}%`} detail="Based on service history" Icon={CircleGauge} tone="blue"/><Metric label="OPEN REPAIR CASES" value={data.repairs.filter(item=>item.stage<4).length} detail={activeRepair?'One case needs attention':'No action required'} Icon={BriefcaseBusiness} tone="amber"/><Metric label="VERIFIED RECORDS" value={data.products.reduce((sum,item)=>sum+Number(item.repairCount||0),0)} detail="Permanent lifecycle entries" Icon={ShieldCheck} tone="violet"/></div>
    {activeRepair?<article className="case-panel">
      <div className="case-heading"><div><span className="case-icon"><Wrench/></span><div><p className="kicker">ACTIVE REPAIR · {activeRepair.id}</p><h2>{activeRepair.productName}</h2><p>{activeRepair.diagnosis?.finding}</p></div></div><span className="case-status">{repairStages[activeRepair.stage]}</span></div>
      <RepairProgress repair={activeRepair}/>
      <div className="case-meta"><div><small>ASSIGNED SERVICE CENTRE</small><b>{activeRepair.technician}</b></div><div><small>LAST UPDATED</small><b>{formatDate(activeRepair.updatedAt)}</b></div><div><small>EXPECTED SERVICE TIME</small><b>{activeRepair.diagnosis?.time||'Pending inspection'}</b></div><button>View case details <ChevronRight/></button></div>
    </article>:<article className="empty-case"><CheckCircle2/><div><h2>No active repair cases</h2><p>Your registered products have no open service requests.</p></div><button className="button secondary-button" onClick={onDiagnose}>Check a device</button></article>}
    <div className="content-grid">
      <article className="panel products-panel"><div className="panel-head"><div><h2>Registered products</h2><p>Current ownership and service condition</p></div><button onClick={onRegister}>Add product <Plus/></button></div><div className="product-table"><div className="product-row table-labels"><span>Product</span><span>Passport</span><span>Condition</span><span>Warranty</span><span></span></div>{data.products.map(product=><div className="product-row" key={product.id}><div className="product-name"><span>{product.category==='Smartphone'?<Smartphone/>:<Cpu/>}</span><div><b>{product.name}</b><small>{product.manufacturer} · {product.serial}</small></div></div><code>{product.id}</code><div className="health-cell"><b>{product.health}%</b><span><i style={{width:`${product.health}%`}}></i></span></div><div className="warranty-cell"><ShieldCheck/><span><b>{product.status}</b><small>{product.warranty}</small></span></div><button className="row-action" aria-label={`Open ${product.name}`}><ChevronRight/></button></div>)}</div></article>
      <article className="panel passport-panel"><div className="panel-head"><div><h2>Product passport</h2><p>Portable device identity</p></div><button>Open record</button></div>{selectedProduct&&<><div className="passport-device"><div className="qr-box"><QrCode/></div><div><p className="kicker">DIGITAL PRODUCT PASSPORT</p><h3>{selectedProduct.name}</h3><code>{selectedProduct.id}</code></div></div><dl><div><dt>Current owner</dt><dd>{session.name}</dd></div><div><dt>Original purchase</dt><dd>{formatDate(selectedProduct.purchaseDate)}</dd></div><div><dt>Repair records</dt><dd>{selectedProduct.repairCount||0} verified</dd></div><div><dt>Serial number</dt><dd>{selectedProduct.serial}</dd></div></dl><div className="verified-note"><ShieldCheck/><span><b>Ownership verified</b><small>Lifecycle changes are time-stamped</small></span></div></>}</article>
    </div>
  </>;
}

function OperationsOverview({session,data,onAdvance}){
  const role=session.role;
  const repair=data.repairs[0];
  const config={
    technician:{kicker:'SERVICE OPERATIONS',title:'Repair work queue',description:'Prioritise inspections, record work, and close verified service cases.',metrics:[['OPEN JOBS',data.repairs.filter(item=>item.stage<4).length,'Across assigned queue',BriefcaseBusiness,'amber'],['DUE TODAY','4','Two priority inspections',CalendarDays,'blue'],['FIRST-TIME FIX','91%','Rolling 30-day rate',CircleGauge,'teal'],['PARTS WAITING','2','Expected before 3:00 PM',PackageCheck,'violet']]},
    manufacturer:{kicker:'PRODUCT RELIABILITY',title:'Fleet and service intelligence',description:'Monitor field health, recurring faults, and digital passport quality.',metrics:[['REGISTERED UNITS',data.products.length,'Across active models',Box,'blue'],['FLEET HEALTH','87%','Up 2.4% this quarter',CircleGauge,'teal'],['OPEN BULLETINS','3','One safety priority',FileText,'amber'],['REPAIRABILITY','8.4','Average model score',Wrench,'violet']]},
    administrator:{kicker:'PLATFORM CONTROL',title:'Operations and trust overview',description:'Review access, product passports, service activity, and safety controls.',metrics:[['ACTIVE USERS','1,248','Across four account roles',UsersRound,'blue'],['PASSPORTS',data.products.length+1246,'98.7% verified',QrCode,'teal'],['OPEN REVIEWS','12','Three require action',ClipboardCheck,'amber'],['PLATFORM STATUS','Healthy','All services available',ShieldCheck,'violet']]}
  }[role];
  return <>
    <div className="page-heading"><div><p className="kicker">{config.kicker}</p><h1>{config.title}</h1><p>{config.description}</p></div><div className="heading-actions"><button className="button secondary-button"><FileText/> Export report</button><button className="button primary-button"><Plus/> {role==='technician'?'Create walk-in job':role==='manufacturer'?'Issue passport':'Invite user'}</button></div></div>
    <div className="metric-grid">{config.metrics.map(([label,value,detail,Icon,tone])=><Metric key={label} label={label} value={value} detail={detail} Icon={Icon} tone={tone}/>)}</div>
    {role==='technician'&&repair&&<article className="case-panel technician-case"><div className="case-heading"><div><span className="case-icon"><Wrench/></span><div><p className="kicker">NEXT PRIORITY · {repair.id}</p><h2>{repair.productName}</h2><p>{repair.customerName} · {repair.diagnosis?.finding}</p></div></div><span className="priority-tag">{repair.diagnosis?.urgency||'Standard'}</span></div><div className="technician-summary"><div><small>REPORTED SYMPTOMS</small><p>{repair.symptoms}</p></div><div><small>ESTIMATED RANGE</small><b>{repair.diagnosis?.estimate}</b></div><div><small>CURRENT STAGE</small><b>{repairStages[repair.stage]}</b></div></div><RepairProgress repair={repair}/><div className="case-footer"><span><ShieldCheck/> Every update becomes part of the product passport.</span><button className="button primary-button" disabled={repair.stage>=4} onClick={()=>onAdvance(repair)}>{repair.stage>=4?'Case completed':`Complete ${repairStages[repair.stage]}`} <ArrowRight/></button></div></article>}
    <div className="ops-grid"><article className="panel queue-panel"><div className="panel-head"><div><h2>{role==='technician'?'Repair queue':role==='manufacturer'?'Model reliability': 'Review queue'}</h2><p>Live operational records</p></div><button>View all</button></div><div className="ops-table"><div className="ops-row table-labels"><span>Record</span><span>Owner / source</span><span>Status</span><span>Updated</span><span></span></div>{(data.repairs.length?data.repairs:[{id:'RPR-23941',productName:'Samsung Galaxy S24',customerName:'Priya N.',stage:1,updatedAt:'2026-08-08'}]).map(item=><div className="ops-row" key={item.id}><div><b>{item.productName}</b><small>{item.id}</small></div><span>{item.customerName}</span><span className="status-chip">{repairStages[item.stage]}</span><span>{formatDate(item.updatedAt)}</span><button className="row-action"><ChevronRight/></button></div>)}</div></article><article className="panel attention-panel"><div className="panel-head"><div><h2>Needs attention</h2><p>Items requiring a decision</p></div></div>{[['Warranty evidence','3 records waiting',FileCheck2],['Safety review','Battery swelling report',TriangleAlert],['Access request','New service centre',UserRound]].map(([title,detail,Icon])=><button key={title}><span><Icon/></span><div><b>{title}</b><small>{detail}</small></div><ChevronRight/></button>)}</article></div>
  </>;
}

function RegisterDialog({onClose,onSave}){
  const [form,setForm]=useState({name:'',category:'Laptop',manufacturer:'',serial:'',purchaseDate:''});
  const [error,setError]=useState('');
  const [busy,setBusy]=useState(false);
  async function submit(event){event.preventDefault();if(Object.values(form).some(value=>!String(value).trim())) return setError('Complete all product details.');setBusy(true);try{await onSave(form)}catch(nextError){setError(nextError.message);setBusy(false)}}
  return <div className="modal" role="presentation" onMouseDown={onClose}><form className="dialog" onSubmit={submit} onMouseDown={event=>event.stopPropagation()}><button type="button" className="dialog-close" onClick={onClose} aria-label="Close"><X/></button><span className="dialog-badge"><Plus/></span><p className="kicker">NEW PRODUCT PASSPORT</p><h2>Register a product</h2><p>Enter the manufacturer details exactly as shown on the device or purchase record.</p><div className="form-grid"><label>Product name<input value={form.name} onChange={event=>setForm({...form,name:event.target.value})} placeholder="Dell Inspiron 15"/></label><label>Category<select value={form.category} onChange={event=>setForm({...form,category:event.target.value})}><option>Laptop</option><option>Smartphone</option><option>Tablet</option><option>Home appliance</option><option>Other electronics</option></select></label><label>Manufacturer<input value={form.manufacturer} onChange={event=>setForm({...form,manufacturer:event.target.value})} placeholder="Dell"/></label><label>Serial number<input value={form.serial} onChange={event=>setForm({...form,serial:event.target.value})} placeholder="Manufacturer serial"/></label><label>Purchase date<input type="date" value={form.purchaseDate} onChange={event=>setForm({...form,purchaseDate:event.target.value})}/></label><label>Purchase evidence<button type="button" className="upload-field"><ImagePlus/> Add receipt later</button></label></div>{error&&<div className="form-alert"><AlertCircle/>{error}</div>}<div className="dialog-actions"><button type="button" className="button secondary-button" onClick={onClose}>Cancel</button><button className="button primary-button" disabled={busy}>{busy?'Creating…':'Create passport'} <ArrowRight/></button></div></form></div>;
}

function DiagnosisDialog({products,onClose,onSubmit}){
  const [productId,setProductId]=useState(products[0]?.id||'');
  const [symptoms,setSymptoms]=useState('');
  const [result,setResult]=useState(null);
  const [error,setError]=useState('');
  const [busy,setBusy]=useState(false);
  const product=products.find(item=>item.id===productId)||products[0];
  function analyse(){if(symptoms.trim().length<12) return setError('Describe the symptoms in at least one short sentence.');setError('');setResult(analyseSymptoms(symptoms))}
  async function requestRepair(){setBusy(true);try{await onSubmit({product,symptoms:symptoms.trim(),diagnosis:result})}catch(nextError){setError(nextError.message);setBusy(false)}}
  return <div className="modal" role="presentation" onMouseDown={onClose}><section className="dialog diagnosis-dialog" onMouseDown={event=>event.stopPropagation()}><button className="dialog-close" onClick={onClose} aria-label="Close"><X/></button><span className="dialog-badge"><Sparkles/></span><p className="kicker">PRELIMINARY DIAGNOSTIC</p>{!result?<><h2>Describe the device problem</h2><p>Record what you can see, hear, smell, or feel. The assessment prepares the repair request; it does not replace inspection.</p><label>Product<select value={productId} onChange={event=>setProductId(event.target.value)}>{products.map(item=><option value={item.id} key={item.id}>{item.name} · {item.id}</option>)}</select></label><label>Observed symptoms<textarea value={symptoms} onChange={event=>setSymptoms(event.target.value)} placeholder="Example: The laptop becomes hot and the fan is unusually loud after ten minutes…"/></label>{error&&<div className="form-alert"><AlertCircle/>{error}</div>}<div className="safety-note"><ShieldCheck/><span><b>Safety first</b><small>Power off the device if there is smoke, swelling, liquid, or burning smell.</small></span></div><div className="dialog-actions"><button className="button secondary-button" onClick={onClose}>Cancel</button><button className="button primary-button" onClick={analyse}>Review symptoms <ArrowRight/></button></div></>:<><div className="diagnosis-result"><div><small>LIKELY SERVICE CATEGORY</small><h2>{result.finding}</h2><p>{product.name} · Based on the symptoms provided</p></div><span>{result.confidence}%<small>match</small></span></div><div className="assessment"><AlertCircle/><p>{result.summary}</p></div><div className="assessment-grid"><div><small>PRIORITY</small><b>{result.urgency}</b></div><div><small>ESTIMATED RANGE</small><b>{result.estimate}</b></div><div><small>TYPICAL SERVICE TIME</small><b>{result.time}</b></div></div><div className="next-actions"><small>BEFORE SERVICE</small>{result.actions.map(action=><span key={action}><CheckCircle2/>{action}</span>)}</div>{error&&<div className="form-alert"><AlertCircle/>{error}</div>}<div className="dialog-actions"><button className="button secondary-button" onClick={()=>setResult(null)}>Edit description</button><button className="button primary-button" disabled={busy} onClick={requestRepair}>{busy?'Submitting…':'Create repair request'} <ArrowRight/></button></div></>}</section></div>;
}

export default function Page(){
  const [session,setSession]=useState(null);
  const [data,setData]=useState({products:[],repairs:[],diagnoses:[]});
  const [loading,setLoading]=useState(false);
  const [active,setActive]=useState('Overview');
  const [dialog,setDialog]=useState('');
  const [toast,setToast]=useState('');
  const [navOpen,setNavOpen]=useState(false);

  async function openWorkspace(account){setLoading(true);setSession(account);const workspace=await loadWorkspace(account);setData(workspace);setActive(navByRole[account.role][0][0]);setLoading(false)}
  async function refresh(){if(!session)return;const workspace=await loadWorkspace(session);setData(workspace);flash('Workspace refreshed')}
  function flash(message){setToast(message);window.setTimeout(()=>setToast(''),2600)}

  useEffect(()=>{
    const demo=getDemoSession();
    if(demo) openWorkspace(demo).catch(()=>setLoading(false));
    if(!firebaseConfigured&&!demo){setLoading(false);return undefined}
    const unsubscribe=observeAccount((account,error)=>{if(account)openWorkspace(account);else if(!demo)setLoading(false);if(error)flash(error.message)});
    return unsubscribe;
  },[]);

  const currentRole=useMemo(()=>session?.role||'customer',[session]);
  async function saveProduct(form){const product=await addProduct(session,form);setData(current=>({...current,products:[product,...current.products]}));setDialog('');flash('Product passport created')}
  async function submitRepair(input){const repair=await createRepair(session,input);setData(current=>({...current,repairs:[repair,...current.repairs]}));setDialog('');flash('Repair request created')}
  async function updateRepair(repair){const updated=await advanceRepair(session,repair);setData(current=>({...current,repairs:current.repairs.map(item=>item.id===updated.id?updated:item)}));flash(`Repair moved to ${repairStages[updated.stage]}`)}
  async function changeRole(role){const next=changeDemoRole(session,role);setSession(next);setActive(navByRole[role][0][0]);const workspace=await loadWorkspace(next);setData(workspace)}
  async function logout(){await signOutAccount(session);setSession(null);setData({products:[],repairs:[],diagnoses:[]});setLoading(false)}

  if(loading) return <main className="loading-page"><Logo/><span></span><p>Opening your RepairLoop workspace…</p></main>;
  if(!session) return <AuthScreen onAuthenticated={openWorkspace}/>;
  return <main className="app-shell" style={{'--accent':roleMeta[currentRole].accent}}>
    <div className={navOpen?'sidebar-wrap open':'sidebar-wrap'} onClick={()=>setNavOpen(false)}><div onClick={event=>event.stopPropagation()}><Sidebar session={session} active={active} setActive={label=>{setActive(label);setNavOpen(false)}} onSignOut={logout}/></div></div>
    <div className="workspace"><Topbar session={session} onRoleChange={changeRole} onRefresh={refresh} onMenu={()=>setNavOpen(true)}/><section className="workspace-content">{currentRole==='customer'?<CustomerOverview session={session} data={data} onRegister={()=>setDialog('register')} onDiagnose={()=>setDialog('diagnose')}/>:<OperationsOverview session={session} data={data} onAdvance={updateRepair}/>}</section></div>
    {dialog==='register'&&<RegisterDialog onClose={()=>setDialog('')} onSave={saveProduct}/>} {dialog==='diagnose'&&<DiagnosisDialog products={data.products} onClose={()=>setDialog('')} onSubmit={submitRepair}/>} {toast&&<div className="toast"><CheckCircle2/>{toast}</div>}
  </main>;
}
