'use client';

import {
  createUserWithEmailAndPassword,
  onAuthStateChanged,
  signInWithEmailAndPassword,
  signOut,
  updateProfile
} from 'firebase/auth';
import {
  addDoc,
  collection,
  doc,
  getDoc,
  getDocs,
  query,
  serverTimestamp,
  setDoc,
  updateDoc,
  where
} from 'firebase/firestore';
import {auth,db,firebaseConfigured} from './firebase';

export const repairStages=['Request received','Technician assigned','Inspection','Repair underway','Ready for pickup'];
export const allowedRoles=['customer','manufacturer','technician','administrator'];

const DEMO_SESSION_KEY='repairloop_demo_session_v2';
const DEMO_DATA_KEY='repairloop_demo_data_v2';

const seedProducts=[
  {id:'RLP-8C24-DL15',name:'Dell Inspiron 15',category:'Laptop',serial:'DL15-9K2A-1842',purchaseDate:'2026-01-12',status:'Good condition',health:92,warranty:'Coverage ends 12 Apr 2027',manufacturer:'Dell',repairCount:1},
  {id:'RLP-77FA-S24',name:'Samsung Galaxy S24',category:'Smartphone',serial:'S24-6Q8M-5421',purchaseDate:'2026-05-09',status:'Battery review due',health:78,warranty:'Coverage ends 09 May 2027',manufacturer:'Samsung',repairCount:0},
  {id:'RLP-19BE-WM7',name:'LG Front Load 7 kg',category:'Home appliance',serial:'LG7-2025-11408',purchaseDate:'2025-11-20',status:'Good condition',health:88,warranty:'Coverage ends 20 Nov 2027',manufacturer:'LG',repairCount:1}
];

const seedRepairs=[{
  id:'RPR-24082',productId:'RLP-8C24-DL15',productName:'Dell Inspiron 15',customerName:'Sarwin Kumar',
  symptoms:'Device runs hot and the fan becomes loud during normal use.',
  diagnosis:{finding:'Cooling system airflow restriction',confidence:88,urgency:'Priority',estimate:'₹600–₹1,800',time:'1–2 hours'},
  stage:2,technician:'Arjun M. · TechCare Chennai',openedAt:'2026-08-08T10:30:00.000Z',updatedAt:'2026-08-09T04:20:00.000Z',
  history:[
    {label:'Request received',time:'08 Aug · 4:00 PM'},
    {label:'Technician assigned',time:'08 Aug · 4:18 PM'},
    {label:'Inspection',time:'09 Aug · 9:50 AM'}
  ]
}];

function initialDemoData(){return {products:seedProducts,repairs:seedRepairs,diagnoses:[]}}

function readDemoData(){
  if(typeof window==='undefined') return initialDemoData();
  try{return JSON.parse(window.localStorage.getItem(DEMO_DATA_KEY))||initialDemoData()}catch{return initialDemoData()}
}

function saveDemoData(data){window.localStorage.setItem(DEMO_DATA_KEY,JSON.stringify(data));return data}

function code(prefix){return `${prefix}-${crypto.randomUUID().slice(0,8).toUpperCase()}`}
function displayTime(){return new Intl.DateTimeFormat('en-IN',{day:'2-digit',month:'short',hour:'2-digit',minute:'2-digit'}).format(new Date())}
function dateValue(value){return value?.toDate?value.toDate().toISOString():value||new Date().toISOString()}

function productFromDoc(snapshot){return {id:snapshot.id,...snapshot.data(),createdAt:dateValue(snapshot.data().createdAt)}}
function repairFromDoc(snapshot){const data=snapshot.data();return {id:snapshot.id,...data,openedAt:dateValue(data.openedAt),updatedAt:dateValue(data.updatedAt)}}

async function ensureProfile(firebaseUser,name){
  const ref=doc(db,'users',firebaseUser.uid);
  const snapshot=await getDoc(ref);
  if(!snapshot.exists()){
    const profile={name:name||firebaseUser.displayName||firebaseUser.email.split('@')[0],email:firebaseUser.email,role:'customer',createdAt:serverTimestamp(),updatedAt:serverTimestamp()};
    await setDoc(ref,profile);
    return {...profile,createdAt:new Date().toISOString(),updatedAt:new Date().toISOString()};
  }
  return snapshot.data();
}

export function observeAccount(callback){
  if(!firebaseConfigured){callback(null);return()=>{}}
  return onAuthStateChanged(auth,async firebaseUser=>{
    if(!firebaseUser){callback(null);return}
    try{
      const profile=await ensureProfile(firebaseUser);
      callback({uid:firebaseUser.uid,email:firebaseUser.email,name:profile.name,role:profile.role||'customer',mode:'firebase'});
    }catch(error){callback(null,error)}
  });
}

export async function registerAccount({name,email,password}){
  if(!firebaseConfigured) throw new Error('Firebase is not connected yet. Open the demo workspace or add the Firebase web configuration.');
  const credential=await createUserWithEmailAndPassword(auth,email,password);
  await updateProfile(credential.user,{displayName:name});
  const profile=await ensureProfile(credential.user,name);
  return {uid:credential.user.uid,email:credential.user.email,name:profile.name,role:profile.role,mode:'firebase'};
}

export async function signInAccount({email,password}){
  if(!firebaseConfigured) throw new Error('Firebase is not connected yet. Open the demo workspace or add the Firebase web configuration.');
  const credential=await signInWithEmailAndPassword(auth,email,password);
  const profile=await ensureProfile(credential.user);
  return {uid:credential.user.uid,email:credential.user.email,name:profile.name,role:profile.role,mode:'firebase'};
}

export async function signOutAccount(session){
  if(session?.mode==='firebase'&&firebaseConfigured) await signOut(auth);
  if(typeof window!=='undefined') window.localStorage.removeItem(DEMO_SESSION_KEY);
}

export function getDemoSession(){
  if(typeof window==='undefined') return null;
  try{return JSON.parse(window.localStorage.getItem(DEMO_SESSION_KEY))}catch{return null}
}

export function openDemo(role='customer'){
  const session={uid:'demo-user',email:'demo@repairloop.app',name:'Sarwin Kumar',role,mode:'demo'};
  window.localStorage.setItem(DEMO_SESSION_KEY,JSON.stringify(session));
  return session;
}

export function changeDemoRole(session,role){
  if(session.mode!=='demo'||!allowedRoles.includes(role)) return session;
  const next={...session,role};
  window.localStorage.setItem(DEMO_SESSION_KEY,JSON.stringify(next));
  return next;
}

export async function loadWorkspace(session){
  if(session.mode==='demo') return readDemoData();
  const staff=['manufacturer','technician','administrator'].includes(session.role);
  const productQuery=staff?collection(db,'products'):query(collection(db,'products'),where('ownerId','==',session.uid));
  const repairQuery=staff?collection(db,'repairs'):query(collection(db,'repairs'),where('customerId','==',session.uid));
  const [productResult,repairResult]=await Promise.all([getDocs(productQuery),getDocs(repairQuery)]);
  const products=productResult.docs.map(productFromDoc).sort((a,b)=>String(b.createdAt).localeCompare(String(a.createdAt)));
  const repairs=repairResult.docs.map(repairFromDoc).sort((a,b)=>String(b.updatedAt).localeCompare(String(a.updatedAt)));
  return {products,repairs,diagnoses:[]};
}

export async function addProduct(session,form){
  const product={
    name:form.name.trim(),category:form.category,serial:form.serial.trim(),purchaseDate:form.purchaseDate,
    manufacturer:form.manufacturer.trim(),status:'Verification pending',health:100,warranty:'Proof of purchase under review',repairCount:0,
    ownerId:session.uid,ownerName:session.name,createdAt:new Date().toISOString()
  };
  if(session.mode==='demo'){
    const data=readDemoData();
    const saved={...product,id:code('RLP')};
    saveDemoData({...data,products:[saved,...data.products]});
    return saved;
  }
  const reference=await addDoc(collection(db,'products'),{...product,createdAt:serverTimestamp()});
  return {...product,id:reference.id};
}

export async function createRepair(session,{product,symptoms,diagnosis}){
  const diagnosisRecord={productId:product.id,ownerId:session.uid,symptoms,assessment:diagnosis,createdAt:new Date().toISOString()};
  const repair={
    productId:product.id,productName:product.name,customerId:session.uid,customerName:session.name,symptoms,diagnosis,
    stage:0,technician:'Awaiting assignment',openedAt:new Date().toISOString(),updatedAt:new Date().toISOString(),
    history:[{label:repairStages[0],time:displayTime()}]
  };
  if(session.mode==='demo'){
    const data=readDemoData();
    const savedDiagnosis={...diagnosisRecord,id:code('DGN')};
    const savedRepair={...repair,id:code('RPR'),diagnosisId:savedDiagnosis.id};
    saveDemoData({...data,diagnoses:[savedDiagnosis,...data.diagnoses],repairs:[savedRepair,...data.repairs]});
    return savedRepair;
  }
  const diagnosisRef=await addDoc(collection(db,'diagnoses'),{...diagnosisRecord,createdAt:serverTimestamp()});
  const repairRef=await addDoc(collection(db,'repairs'),{...repair,diagnosisId:diagnosisRef.id,openedAt:serverTimestamp(),updatedAt:serverTimestamp()});
  return {...repair,id:repairRef.id,diagnosisId:diagnosisRef.id};
}

export async function advanceRepair(session,repair){
  const nextStage=Math.min(repair.stage+1,repairStages.length-1);
  const history=[...(repair.history||[]),{label:repairStages[nextStage],time:displayTime()}];
  const update={stage:nextStage,history,technician:repair.technician==='Awaiting assignment'?'Arjun M. · TechCare Chennai':repair.technician,updatedAt:new Date().toISOString()};
  if(session.mode==='demo'){
    const data=readDemoData();
    const repairs=data.repairs.map(item=>item.id===repair.id?{...item,...update}:item);
    saveDemoData({...data,repairs});
    return {...repair,...update};
  }
  if(!['technician','administrator'].includes(session.role)) throw new Error('Only a technician or administrator can update a repair stage.');
  await updateDoc(doc(db,'repairs',repair.id),{...update,updatedAt:serverTimestamp()});
  return {...repair,...update};
}

export {firebaseConfigured};
