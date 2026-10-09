/**
 * AZURA HOUSE - MASTER SCRIPT
 */

document.addEventListener("DOMContentLoaded", function() {
    const urlParams = new URLSearchParams(window.location.search);

    // --- A. Category Filter (index.jsp) ---
    const filterButtons = document.querySelectorAll('.filter-btn');
    filterButtons.forEach(btn => {
        btn.addEventListener('click', function(e) {
            e.preventDefault();
            
            // Toggle Active UI
            filterButtons.forEach(b => b.classList.remove('active', 'btn-primary'));
            this.classList.add('active', 'btn-primary');

            const category = this.getAttribute('data-filter');
            const items = document.querySelectorAll('.menu-item-container');

            items.forEach(item => {
                const itemCat = item.getAttribute('data-category');
                if (category === 'all' || itemCat === category) {
                    item.style.display = 'block';
                } else {
                    item.style.display = 'none';
                }
            });
        });
    });

    // --- B. Edit Menu Modal (dashboard.jsp) ---
    const editButtons = document.querySelectorAll('.edit-menu-btn');
    editButtons.forEach(btn => {
        btn.addEventListener('click', function() {
            const modalEl = document.getElementById('editMenuModal');
            if (modalEl) {
                // Populate Modal Fields
                document.getElementById('editMenuId').value = this.dataset.id;
                document.getElementById('editMenuName').value = this.dataset.name;
                document.getElementById('editMenuPrice').value = this.dataset.price;
                document.getElementById('editMenuCategory').value = this.dataset.category;
                
                // Show Modal using Bootstrap Instance
                const modalInstance = bootstrap.Modal.getOrCreateInstance(modalEl);
                modalInstance.show();
            }
        });
    });

    // --- C. Order Review Logic (Customer Side) ---
    const placeOrderBtn = document.getElementById("placeOrderBtn");
    if (placeOrderBtn) {
        placeOrderBtn.addEventListener("click", function() {
            const checkboxes = document.querySelectorAll('input[name="foodItem"]:checked');
            
            if (checkboxes.length === 0) {
                alert("Please select at least one item first!");
                return;
            }

            const summaryList = document.getElementById("orderSummaryList");
            const modalTotalDisplay = document.getElementById("modalTotal");
            if (!summaryList) return;

            summaryList.innerHTML = ""; 
            let total = 0;

            checkboxes.forEach((item) => {
                const name = item.value;
                const priceAttr = item.getAttribute("data-price");
                const price = parseFloat(priceAttr) || 0;
                
                const qtyInputs = document.getElementsByName(`qty_${name}`);
                const qty = (qtyInputs.length > 0) ? parseInt(qtyInputs[0].value) : 1;
                
                const sub = price * qty;
                total += sub;

                const itemRow = `
                    <div class="d-flex justify-content-between mb-2 border-bottom pb-1">
                        <div class="text-dark">
                            <span class="fw-bold">${name}</span>
                            <br><small class="text-muted">Quantity: ${qty}</small>
                        </div>
                        <div class="text-dark fw-bold align-self-center">
                            RM ${sub.toFixed(2)}
                        </div>
                    </div>`;
                
                summaryList.insertAdjacentHTML('beforeend', itemRow);
            });

            if (modalTotalDisplay) {
                modalTotalDisplay.innerText = `RM ${total.toFixed(2)}`;
            }

            const hiddenTotal = document.getElementById("totalPriceHidden");
            if (hiddenTotal) {
                hiddenTotal.value = total.toFixed(2); 
            }

            const confirmModalEl = document.getElementById('confirmModal');
            if (confirmModalEl) {
                bootstrap.Modal.getOrCreateInstance(confirmModalEl).show();
            }
        });
    }

    // --- D. Search Tables (Owner Side) ---
    function setupSearch(inputId, tableId) {
        const input = document.getElementById(inputId);
        if (input) {
            input.addEventListener('input', function() {
                const filter = this.value.toLowerCase();
                const rows = document.querySelectorAll(`#${tableId} .searchable-row`);
                rows.forEach(row => {
                    const text = row.querySelector('.item-name').textContent.toLowerCase();
                    row.style.display = text.includes(filter) ? "" : "none";
                });
            });
        }
    }
    setupSearch('inventorySearch', 'inventoryTable');
    setupSearch('menuSearch', 'menuTable');

    // --- E. Handle Success Redirects ---
    if (urlParams.has('trxId')) {
        const successModalEl = document.getElementById('successModal');
        if (successModalEl) {
            bootstrap.Modal.getOrCreateInstance(successModalEl).show();
            const cleanUrl = window.location.origin + window.location.pathname + "?table=" + (urlParams.get('table') || 'Counter');
            window.history.replaceState({}, document.title, cleanUrl);
        }
    }
});

/**
 * Global function for Counter Payment (Owner Side)
 * isTakeout (boolean) ensures full payment for takeout orders
 */
function openCounterPayment(orderId, itemsPipe, pricesPipe, isTakeout) {
    const orderIdInput = document.getElementById('counterOrderId');
    if(orderIdInput) orderIdInput.value = orderId;

    const listContainer = document.getElementById('counterItemList');
    const instruction = document.getElementById('paymentInstruction');
    if(!listContainer) return;

    listContainer.innerHTML = '';
    
    // UI Update based on Takeout status
    if (instruction) {
        instruction.innerText = isTakeout ? "Takeout orders require full payment:" : "Select items being paid now:";
    }

    const items = itemsPipe.split('|').filter(i => i.trim() !== "");
    const prices = pricesPipe.split('|').filter(p => p.split("").some(c => !isNaN(c))); // Filter valid numbers
    
    items.forEach((item, index) => {
        const price = prices[index] || "0.00";
        // If Takeout, we disable the checkbox so items cannot be unchecked
        const disabledAttr = isTakeout ? "disabled" : "";
        
        listContainer.innerHTML += `
            <div class="form-check mb-2 p-2 border rounded d-flex align-items-center">
                <input class="form-check-input mt-0 me-3 counter-pay-chk" 
                       type="checkbox" name="payItem" value="${index}" 
                       id="chk_${index}" data-price="${price}" checked ${disabledAttr}
                       onchange="updateCounterTotal()">
                <label class="form-check-label flex-grow-1 d-flex justify-content-between align-items-center text-dark" for="chk_${index}">
                    <span>${item}</span>
                    <span class="fw-bold text-success">RM ${price}</span>
                </label>
            </div>`;
    });

    updateCounterTotal();
    const modalEl = document.getElementById('counterPaymentModal');
    if(modalEl) {
        bootstrap.Modal.getOrCreateInstance(modalEl).show();
    }
}

/**
 * Calculates the current sum of checked items in the counter modal
 */
function updateCounterTotal() {
    let total = 0;
    const checkboxes = document.querySelectorAll('.counter-pay-chk:checked');
    const submitBtn = document.getElementById('processCounterPaymentBtn');
    const display = document.getElementById('selectionTotalRM');

    checkboxes.forEach(chk => {
        total += parseFloat(chk.getAttribute('data-price')) || 0;
    });

    if(display) display.innerText = `RM ${total.toFixed(2)}`;

    if (submitBtn) {
        if (total === 0) {
            submitBtn.disabled = true;
            submitBtn.innerText = "Select items to pay";
        } else {
            submitBtn.disabled = false;
            submitBtn.innerText = "Process Payment";
        }
    }
}