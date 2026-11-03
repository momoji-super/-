// Usage: node run_sim.cjs [ModelSim win64 directory]
const fs=require('fs'),path=require('path'),{spawnSync}=require('child_process');
const root=path.resolve(__dirname,'..');
const bin=process.argv[2]||'C:/FPGA_SoftWare/ModelSim_10.5se/win64';
const sim=path.join(__dirname,'sim');fs.mkdirSync(sim,{recursive:true});
const lib='validation_motion_v3/sim/work_'+Date.now();
function run(tool,args){
    const r=spawnSync(path.join(bin,tool+'.exe'),args,{cwd:root,encoding:'utf8',windowsHide:true,maxBuffer:16*1024*1024});
    if(r.error)throw r.error;
    process.stdout.write(r.stdout||'');process.stderr.write(r.stderr||'');
    if(r.status!==0)throw Error(tool+' exited '+r.status);
}
const rtl=fs.readdirSync(path.join(root,'user_source/hdl_source/hand_gesture')).filter(n=>n.endsWith('.v'))
    .map(n=>'user_source/hdl_source/hand_gesture/'+n);
const sources=rtl.concat([
    'user_source/hdl_source/isp/sim/motion_stability_tb.v',
    'user_source/hdl_source/hand_gesture/sim/hand_temporal_vote_tb.v',
    'user_source/hdl_source/hand_gesture/sim/hand_mask_frontend_tb.v',
    'user_source/hdl_source/hand_gesture/sim/hand_pipeline_tb.v',
    'user_source/hdl_source/hdmi_mixer.v',
    'user_source/hdl_source/sim/hdmi_mixer_osd_switch_tb.v',
    'user_source/hdl_source/sim/hdmi_mixer_age_tb.v',
    'user_source/hdl_source/isp/target_detect_track.v',
    'validation_motion_v3/target_detect_track_before.v',
    'user_source/hdl_source/isp/sim/target_pipeline_equivalence_tb.v',
    'user_source/hdl_source/isp/sim/red_laser_peak_tb.v',
    'user_source/hdl_source/gimbal_red_tracker.v',
    'user_source/hdl_source/sim/red_tracking_chain_tb.v']);
run('vlib',[lib]);run('vlog',['-work',lib,...sources]);
const tests=['motion_stability_tb','hand_temporal_vote_tb','hand_mask_frontend_tb','hand_pipeline_tb','hdmi_mixer_osd_switch_tb',
    'hdmi_mixer_age_tb','target_pipeline_equivalence_tb','red_laser_peak_tb','red_tracking_chain_tb'];
for(const test of tests){
    const log='validation_motion_v3/sim/'+test+'.log';
    run('vsim',['-c','-onfinish','exit','-lib',lib,test,'-l',log,'-do','run -all; quit -f']);
    const report=fs.readFileSync(path.join(root,log),'utf8');
    if(/\*\* (Fatal|Error)/.test(report)||!report.includes('PASS'))throw Error('Failed: '+test);
}
fs.writeFileSync(path.join(sim,'summary.txt'),tests.map(t=>'PASS '+t).join('\n')+'\nALL_9_REGRESSIONS_PASS\n');
console.log('ALL_9_REGRESSIONS_PASS');
