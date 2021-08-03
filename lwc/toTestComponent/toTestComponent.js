import { LightningElement } from 'lwc';

export default class ToTestComponent extends LightningElement {
    className = 'hello';
    handleClick(event){
        this.className = 'Being called from product...';
        alert('what is ei');
    }
}