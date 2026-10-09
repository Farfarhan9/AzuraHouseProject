function toggleQR() {
    const method = document.getElementById('payMethod').value;
    const qrDisplay = document.getElementById('qrDisplay');
    
    if (method === 'E-Wallet') {
        qrDisplay.style.display = 'block';
    } else {
        qrDisplay.style.display = 'none';
    }
}