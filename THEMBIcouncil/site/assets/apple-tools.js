'use strict';
(() => {
  const byId = id => document.getElementById(id);
  const status = byId('apple-tools-status');
  const say = text => { if(status) status.textContent = text; };
  const str = id => (byId(id)?.value||'').trim();
  const esc = v => String(v).replace(/\\/g,'\\\\').replace(/\r\n?|\n/g,'\\n').replace(/,/g,'\\,').replace(/;/g,'\\;');
  const save = (name,content,type) => {
    const url=URL.createObjectURL(new Blob([content],{type}));
    const a=document.createElement('a');
    a.href=url;a.download=name;document.body.appendChild(a);a.click();a.remove();
    setTimeout(()=>URL.revokeObjectURL(url),30000);
  };
  const safeName = value => value.replace(/[^a-z0-9_-]/gi,'_').slice(0,48)||'document';
  const icalTime = date => date.toISOString().replace(/[-:]/g,'').replace(/\.\d{3}Z$/,'Z');
  byId('create-ics')?.addEventListener('click',()=>{
    const title=str('cal-title'),startValue=str('cal-start'),endValue=str('cal-end');
    if(!title||!startValue||title.length>180){say('Enter an event title and start date.');return}
    const start=new Date(startValue);const end=endValue?new Date(endValue):new Date(start.getTime()+3600000);
    if(!Number.isFinite(start.getTime())||!Number.isFinite(end.getTime())||end<=start){say('Use valid dates; end must be after start.');return}
    const uid=crypto.randomUUID()+'@thembicouncil.local';
    const lines=['BEGIN:VCALENDAR','VERSION:2.0','PRODID:-//THEMBIcouncil//Local Export//EN','BEGIN:VEVENT','UID:'+uid,'DTSTAMP:'+icalTime(new Date()),'DTSTART:'+icalTime(start),'DTEND:'+icalTime(end),'SUMMARY:'+esc(title),'DESCRIPTION:Created locally by THEMBIcouncil. Review before adding to a calendar.','END:VEVENT','END:VCALENDAR'];
    save('thembicouncil-event.ics',lines.join('\r\n')+'\r\n','text/calendar;charset=utf-8');
    say('Calendar file generated on this device. Open/import it in your calendar app; no event was created remotely.');
  });
  byId('create-vcf')?.addEventListener('click',()=>{
    const name=str('contact-name'),email=str('contact-email'),phone=str('contact-phone');
    if(!name||name.length>180){say('Enter a contact name.');return}
    if(email&&(!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)||email.length>160)){say('Check the contact email.');return}
    if(phone&&phone.length>40){say('Phone field is too long.');return}
    const lines=['BEGIN:VCARD','VERSION:3.0','FN:'+esc(name),...(email?['EMAIL:'+esc(email)]:[]),...(phone?['TEL:'+esc(phone)]:[]),'END:VCARD'];
    save('thembicouncil-'+safeName(name)+'.vcf',lines.join('\r\n')+'\r\n','text/vcard;charset=utf-8');
    say('Contact card generated locally. Review and import it in Contacts; nothing was saved to an address book automatically.');
  });
  byId('create-maps')?.addEventListener('click',()=>{
    const q=str('maps-query'),a=byId('maps-result');
    if(!a||!q||q.length>250){say('Enter a place or destination.');return}
    a.href='https://maps.apple.com/?q='+encodeURIComponent(q);
    a.textContent='Open '+q+' in Apple Maps';
    a.hidden=false;
    say('Maps link ready. Opening it is your choice; no current location was requested.');
  });
  byId('create-mail')?.addEventListener('click',()=>{
    const to=str('mail-to'),subject=str('mail-subject'),a=byId('mail-result');
    if(!a||!to||!/^[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,}$/.test(to)||to.length>160){say('Enter a valid recipient address.');return}
    a.href='mailto:'+to+'?subject='+encodeURIComponent(subject.slice(0,180));
    a.textContent='Compose message in Apple Mail or default mail app';
    a.hidden=false;
    say('Compose link ready. Nothing is sent unless you review and send it in your mail app.');
  });
})();
