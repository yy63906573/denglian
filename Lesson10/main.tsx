import { StrictMode } from 'react'
import { createRoot } from 'react-dom/client'
import './index.css'
import App from './App.tsx'
import { WalletConnectLogin } from './components/WalletConnectLogin';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <WalletConnectLogin>
      {/* <App /> */}
    </WalletConnectLogin>
  </StrictMode>
);
