<img width="680" height="660" alt="v36-network-diagram" src="https://github.com/user-attachments/assets/1a9db402-2550-4a76-b9bd-04e5549b1e9a" />

<svg width="680" height="660" viewBox="0 0 680 660" xmlns="http://www.w3.org/2000/svg" role="img" xmlns:c2pa="http://c2pa.org/manifest"><metadata>

<rect width="680" height="660" fill="#FFFFFF"/>

<defs>
<marker id="arrow" viewBox="0 0 10 10" refX="8" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
  <path d="M2 1L8 5L2 9" fill="none" stroke="#5F5E5A" stroke-width="1.5" stroke-linecap="round" stroke-linejoin="round"/>
</marker>
</defs>

<text x="340" y="30" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#2C2C2A">Internet</text>
<text x="340" y="48" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#5F5E5A">HTTP/HTTPS 80,443 — tillåts</text>
<line x1="340" y1="56" x2="340" y2="98" stroke="#5F5E5A" stroke-width="1.5" marker-end="url(#arrow)"/>

<rect x="100" y="100" width="480" height="500" rx="20" fill="#E6F1FB" stroke="#185FA5" stroke-width="1"/>
<text x="120" y="128" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#0C447C">vnet-novatrix</text>
<text x="120" y="146" font-family="Arial, sans-serif" font-size="12" fill="#185FA5">172.16.0.0/16 · Sweden Central</text>

<rect x="130" y="170" width="420" height="240" rx="12" fill="#E1F5EE" stroke="#0F6E56" stroke-width="1"/>
<text x="146" y="196" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#085041">snet-web (publikt)</text>
<text x="146" y="214" font-family="Arial, sans-serif" font-size="12" fill="#0F6E56">172.16.1.0/24</text>

<rect x="150" y="228" width="380" height="48" rx="8" fill="#FAECE7" stroke="#993C1D" stroke-width="1"/>
<text x="340" y="248" text-anchor="middle" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#712B13">vm-novatrix-web</text>
<text x="340" y="266" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#993C1D">172.16.1.4</text>

<rect x="150" y="286" width="380" height="104" rx="8" fill="#EEEDFE" stroke="#534AB7" stroke-width="1"/>
<text x="166" y="306" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#3C3489">nsg-web</text>
<text x="166" y="326" font-family="Arial, sans-serif" font-size="12" fill="#534AB7">80/443 — tillåts</text>
<text x="166" y="344" font-family="Arial, sans-serif" font-size="12" fill="#534AB7">SSH från admin-IP — tillåts</text>
<text x="166" y="362" font-family="Arial, sans-serif" font-size="12" fill="#534AB7">Övrig inbound — nekas</text>

<rect x="130" y="430" width="420" height="140" rx="12" fill="#F1EFE8" stroke="#5F5E5A" stroke-width="1"/>
<text x="146" y="456" font-family="Arial, sans-serif" font-size="14" font-weight="600" fill="#444441">snet-db (privat)</text>
<text x="146" y="474" font-family="Arial, sans-serif" font-size="12" fill="#5F5E5A">172.16.2.0/24</text>
<text x="146" y="500" font-family="Arial, sans-serif" font-size="12" fill="#5F5E5A">Privat / backend (reserverat, v37)</text>

<text x="340" y="630" text-anchor="middle" font-family="Arial, sans-serif" font-size="12" fill="#791F1F">Default deny: all annan inkommande trafik blockeras</text>
</svg>
